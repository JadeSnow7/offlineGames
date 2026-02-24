/// Board-aware heuristic AI for Card Duel CCG.
enum CardDuelAI {

  // MARK: - Play Phase

  /// Returns an ordered list of (handIndex, optional target) representing cards the AI will play.
  /// Greedy: plays highest value-density cards until mana runs out or board is full.
  static func playActions(state: CardDuelState) -> [(handIndex: Int, target: Target?)] {
    var actions: [(handIndex: Int, target: Target?)] = []
    var simulatedMana = state.aiMana
    var simulatedBoardCount = state.aiBoard.count
    var simulatedHand = Array(state.aiHand.enumerated())  // (originalIndex, card)

    // Sort by value density descending, but prefer lethal / face spells when needed
    let sorted = simulatedHand.sorted { a, b in
      valueDensity(a.element, state: state) > valueDensity(b.element, state: state)
    }

    for (originalIndex, card) in sorted {
      guard simulatedMana >= card.cost else { continue }
      if card.cardType == .minion && simulatedBoardCount >= CardDuelState.maxBoardSize { continue }

      let target = chooseTarget(for: card, state: state)

      // Skip spells requiring a target if no valid target exists
      if needsTarget(card) && target == nil { continue }

      actions.append((handIndex: originalIndex, target: target))
      simulatedMana -= card.cost
      if card.cardType == .minion { simulatedBoardCount += 1 }
    }

    return actions
  }

  // MARK: - Attack Phase

  /// Returns an ordered list of (attackerID, target) for all minions that can attack.
  static func attackActions(state: CardDuelState) -> [(attackerID: Int, target: Target)] {
    var actions: [(attackerID: Int, target: Target)] = []
    let taunters = state.playerBoard.filter { $0.card.keywords.contains(.taunt) }

    for minion in state.aiBoard where minion.canAttack && minion.currentAttack > 0 {
      let target = chooseAttackTarget(for: minion, taunters: taunters, state: state)
      actions.append((attackerID: minion.id, target: target))
    }

    return actions
  }

  // MARK: - Private helpers

  private static func valueDensity(_ card: DuelCard, state: CardDuelState) -> Double {
    guard card.cost > 0 else { return 0 }
    switch card.cardType {
    case .minion:
      let stats = Double(card.attack + card.health)
      let keywordBonus = Double(card.keywords.count) * 1.5
      return (stats + keywordBonus) / Double(card.cost)
    case .spell:
      guard let effect = card.spellEffect else { return 0 }
      switch effect {
      case .damageTarget(let n):
        // Massive bonus if lethal to enemy hero
        if n >= state.playerHP { return 1000.0 }
        return Double(n) / Double(card.cost)
      case .healTarget(let n):
        let urgency = state.aiHP <= 10 ? 2.0 : 1.0
        return Double(n) * urgency / Double(card.cost)
      case .aoeEnemyMinions(let n):
        let targetsHit = state.playerBoard.filter { $0.currentHealth <= n }.count
        return Double(targetsHit * n) / Double(card.cost)
      case .drawCards(let n):
        return Double(n * 2) / Double(card.cost)
      case .buffMinion(let a, let h):
        return Double(a + h) / Double(card.cost)
      }
    }
  }

  /// Picks a sensible target for a spell that needs one.
  private static func chooseTarget(for card: DuelCard, state: CardDuelState) -> Target? {
    guard let effect = card.spellEffect else { return nil }
    switch effect {
    case .damageTarget(_):
      // Prefer lethal on hero, otherwise hit highest-attack enemy minion
      let enemyMinions = state.playerBoard.sorted { $0.currentAttack > $1.currentAttack }
      return enemyMinions.first.map { .minion(id: $0.id) } ?? .enemyHero
    case .healTarget(_):
      return .friendlyHero
    case .buffMinion(_, _):
      // Buff highest-attack friendly minion
      let ally = state.aiBoard.sorted { $0.currentAttack > $1.currentAttack }.first
      return ally.map { .minion(id: $0.id) }
    case .aoeEnemyMinions, .drawCards:
      return nil
    }
  }

  /// Determines attack target respecting Taunt.
  private static func chooseAttackTarget(
    for attacker: BoardMinion,
    taunters: [BoardMinion],
    state: CardDuelState
  ) -> Target {
    // Rush minions on summon turn may NOT attack the hero
    let rushRestricted = attacker.card.keywords.contains(.rush) && attacker.summonedThisTurn

    // Must attack Taunt minions first
    if !taunters.isEmpty {
      // Trade if we can kill a taunter for free (or less damage than we'd take from others)
      let bestKill = taunters.first { $0.currentHealth <= attacker.currentAttack }
      return .minion(id: (bestKill ?? taunters.first!).id)
    }

    // Try to make a favourable trade (kill enemy minion without dying if possible)
    let favorableTrade = state.playerBoard.first {
      $0.currentHealth <= attacker.currentAttack && attacker.currentHealth > $0.currentAttack
    }
    if let trade = favorableTrade {
      return .minion(id: trade.id)
    }

    // No favourable trade — go face unless Rush-restricted
    if !rushRestricted {
      return .enemyHero
    }

    // Rush-restricted: hit any enemy minion
    if let anyMinion = state.playerBoard.first {
      return .minion(id: anyMinion.id)
    }

    // No minions to attack; Rush minion skips (reducer will handle gracefully)
    return .enemyHero
  }

  private static func needsTarget(_ card: DuelCard) -> Bool {
    guard let effect = card.spellEffect else { return false }
    switch effect {
    case .damageTarget, .healTarget, .buffMinion: return true
    case .aoeEnemyMinions, .drawCards: return false
    }
  }
}
