import CoreEngine
import Foundation

/// Pure reducer for Card Duel CCG turn-based combat.
public let cardDuelReducer: Reduce<CardDuelState, CardDuelAction> = { state, action in
  var s = state

  switch action {

  // MARK: - Session Lifecycle

  case .start:
    var fresh = CardDuelState(seed: s.rng.nextUInt64())
    setupNewGame(state: &fresh)
    return (fresh, .none)

  case .pause:
    guard !s.isGameOver else { return (s, .none) }
    s.isRunning = false
    log(&s, "Paused.")
    return (s, .none)

  case .resume:
    guard !s.isGameOver, !s.isRunning else { return (s, .none) }
    s.isRunning = true
    log(&s, "Resumed.")
    if s.turnPhase == .aiPlay {
      return (s, .run { .aiPlayPhase })
    }
    if s.turnPhase == .aiAttack {
      return (s, .run { .aiAttackPhase })
    }
    return (s, .none)

  case .reset:
    return (CardDuelState(seed: state.seed), .none)

  // MARK: - Player Actions

  case .playCard(let handIndex, let target):
    guard s.isRunning, !s.isGameOver, s.turnPhase == .playerMain else { return (s, .none) }
    guard s.playerHand.indices.contains(handIndex) else { return (s, .none) }

    let card = s.playerHand[handIndex]
    guard s.playerMana >= card.cost else {
      log(&s, "Insufficient mana to play \(card.nameKey).")
      return (s, .none)
    }

    // Board full check for minions
    if card.cardType == .minion, s.playerBoard.count >= CardDuelState.maxBoardSize {
      log(&s, "Board is full.")
      return (s, .none)
    }

    s.playerHand.remove(at: handIndex)
    s.playerMana -= card.cost

    switch card.cardType {
    case .minion:
      let minion = BoardMinion(from: card, id: card.id)
      s.playerBoard.append(minion)
      log(&s, "Player summoned \(card.nameKey) (\(card.attack)/\(card.health)).")

    case .spell:
      guard let effect = card.spellEffect else { break }
      resolveSpell(effect: effect, caster: .player, target: target, state: &s)
    }

    removeDead(state: &s)
    if checkGameOver(state: &s) { return (s, .none) }
    updateScore(state: &s)
    return (s, .none)

  case .minionAttack(let attackerID, let target):
    guard s.isRunning, !s.isGameOver, s.turnPhase == .playerMain else { return (s, .none) }
    guard let attackerIdx = s.playerBoard.firstIndex(where: { $0.id == attackerID }),
      s.playerBoard[attackerIdx].canAttack,
      s.playerBoard[attackerIdx].currentAttack > 0
    else { return (s, .none) }

    // Taunt enforcement
    let taunters = s.aiBoard.filter { $0.card.keywords.contains(.taunt) }
    if !taunters.isEmpty {
      if case .minion(let targetID) = target {
        guard taunters.contains(where: { $0.id == targetID }) else {
          log(&s, "Must attack a Taunt minion first.")
          return (s, .none)
        }
      } else {
        log(&s, "Must attack a Taunt minion first.")
        return (s, .none)
      }
    }

    // Rush restriction on summon turn: can't go face
    if s.playerBoard[attackerIdx].card.keywords.contains(.rush),
      s.playerBoard[attackerIdx].summonedThisTurn,
      case .enemyHero = target
    {
      log(&s, "Rush minions cannot attack the hero on summon turn.")
      return (s, .none)
    }

    let attackPower = s.playerBoard[attackerIdx].currentAttack
    s.playerBoard[attackerIdx].canAttack = false

    switch target {
    case .enemyHero:
      let dmg = dealDamageToHero(amount: attackPower, side: .ai, state: &s)
      log(&s, "\(s.playerBoard[attackerIdx].card.nameKey) attacked enemy hero for \(dmg).")

    case .friendlyHero:
      return (s, .none)  // Invalid choice

    case .minion(let targetID):
      if let defIdx = s.aiBoard.firstIndex(where: { $0.id == targetID }) {
        let defAtk = s.aiBoard[defIdx].currentAttack
        let atkName = s.playerBoard[attackerIdx].card.nameKey
        let defName = s.aiBoard[defIdx].card.nameKey
        dealDamageToMinion(amount: attackPower, index: defIdx, board: &s.aiBoard)
        dealDamageToMinion(amount: defAtk, index: attackerIdx, board: &s.playerBoard)
        log(&s, "\(atkName) traded with \(defName).")
      }
    }

    removeDead(state: &s)
    if checkGameOver(state: &s) { return (s, .none) }
    updateScore(state: &s)
    return (s, .none)

  // MARK: - Turn Management

  case .endTurn:
    guard s.isRunning, !s.isGameOver, s.turnPhase == .playerMain else { return (s, .none) }
    // Reset attack flags on player board; summonedThisTurn → false
    for i in s.playerBoard.indices {
      s.playerBoard[i].canAttack = false
      s.playerBoard[i].summonedThisTurn = false
    }
    // Move to AI play phase
    s.turnPhase = .aiPlay
    s.aiMaxMana = min(s.aiMaxMana + 1, CardDuelState.maxMana)
    s.aiMana = s.aiMaxMana
    // Draw for AI
    drawCard(for: .ai, state: &s)
    // Refresh AI board
    for i in s.aiBoard.indices {
      s.aiBoard[i].canAttack = true
      s.aiBoard[i].summonedThisTurn = false
    }
    log(&s, "AI turn begins (mana \(s.aiMana)/\(s.aiMaxMana)).")
    return (
      s,
      .run {
        try await Task.sleep(for: .milliseconds(400))
        return .aiPlayPhase
      }
    )

  case .aiPlayPhase:
    guard s.isRunning, !s.isGameOver, s.turnPhase == .aiPlay else { return (s, .none) }

    let plays = CardDuelAI.playActions(state: s)
    for play in plays {
      guard s.aiHand.indices.contains(play.handIndex) else { continue }
      let card = s.aiHand[play.handIndex]
      guard s.aiMana >= card.cost else { continue }

      if card.cardType == .minion, s.aiBoard.count >= CardDuelState.maxBoardSize { continue }

      s.aiHand.remove(at: play.handIndex)
      s.aiMana -= card.cost

      switch card.cardType {
      case .minion:
        var minion = BoardMinion(from: card, id: card.id)
        // Apply Rush/Charge for AI minions
        if card.keywords.contains(.charge) { minion.canAttack = true }
        if card.keywords.contains(.rush) { minion.canAttack = true }
        s.aiBoard.append(minion)
        log(&s, "AI summoned \(card.nameKey) (\(card.attack)/\(card.health)).")

      case .spell:
        if let effect = card.spellEffect {
          resolveSpell(effect: effect, caster: .ai, target: play.target, state: &s)
        }
      }
    }

    removeDead(state: &s)
    if checkGameOver(state: &s) { return (s, .none) }

    s.turnPhase = .aiAttack
    return (
      s,
      .run {
        try await Task.sleep(for: .milliseconds(500))
        return .aiAttackPhase
      }
    )

  case .aiAttackPhase:
    guard s.isRunning, !s.isGameOver, s.turnPhase == .aiAttack else { return (s, .none) }

    let attacks = CardDuelAI.attackActions(state: s)
    for attack in attacks {
      guard let attackerIdx = s.aiBoard.firstIndex(where: { $0.id == attack.attackerID }),
        s.aiBoard[attackerIdx].canAttack
      else { continue }

      let attackPower = s.aiBoard[attackerIdx].currentAttack
      s.aiBoard[attackerIdx].canAttack = false
      let atkName = s.aiBoard[attackerIdx].card.nameKey

      switch attack.target {
      case .enemyHero, .friendlyHero:
        let dmg = dealDamageToHero(amount: attackPower, side: .player, state: &s)
        log(&s, "AI \(atkName) attacked your hero for \(dmg).")

      case .minion(let targetID):
        if let defIdx = s.playerBoard.firstIndex(where: { $0.id == targetID }) {
          let defAtk = s.playerBoard[defIdx].currentAttack
          let defName = s.playerBoard[defIdx].card.nameKey
          dealDamageToMinion(amount: attackPower, index: defIdx, board: &s.playerBoard)
          dealDamageToMinion(amount: defAtk, index: attackerIdx, board: &s.aiBoard)
          log(&s, "AI \(atkName) traded with \(defName).")
        }
      }

      removeDead(state: &s)
      if checkGameOver(state: &s) { return (s, .none) }
    }

    return (s, .run { .startPlayerTurn })

  case .startPlayerTurn:
    guard s.isRunning, !s.isGameOver else { return (s, .none) }
    s.turnNumber += 1
    s.playerMaxMana = min(s.playerMaxMana + 1, CardDuelState.maxMana)
    s.playerMana = s.playerMaxMana
    drawCard(for: .player, state: &s)
    // Refresh player board
    for i in s.playerBoard.indices {
      s.playerBoard[i].canAttack = true
      s.playerBoard[i].summonedThisTurn = false
    }
    s.turnPhase = .playerMain
    log(&s, "Your turn (mana \(s.playerMana)/\(s.playerMaxMana)).")
    updateScore(state: &s)
    return (s, .none)
  }
}

// MARK: - Setup

private func setupNewGame(state: inout CardDuelState) {
  state.playerDeck = CardFactory.makeDeck(
    size: CardDuelState.deckSize, startingID: 0, rng: &state.rng)
  state.aiDeck = CardFactory.makeDeck(
    size: CardDuelState.deckSize, startingID: 10_000, rng: &state.rng)

  for _ in 0..<CardDuelState.initialHandSize {
    drawCard(for: .player, state: &state)
    drawCard(for: .ai, state: &state)
  }

  // First turn: player goes first with 1 mana (no draw on turn 1)
  state.playerMaxMana = 1
  state.playerMana = 1
  state.aiMaxMana = 0
  state.aiMana = 0
  state.turnNumber = 1
  state.turnPhase = .playerMain
  state.isRunning = true
  state.isGameOver = false
  log(&state, "Duel started. Your turn (mana 1/1).")
  updateScore(state: &state)
}

// MARK: - Draw

private func drawCard(for owner: CardDuelState.TurnOwner, state: inout CardDuelState) {
  switch owner {
  case .player:
    guard !state.playerDeck.isEmpty else { return }
    if state.playerHand.count >= CardDuelState.maxHandSize {
      let burned = state.playerDeck.removeFirst()
      log(&state, "Player burned \(burned.nameKey) (hand full).")
      return
    }
    state.playerHand.append(state.playerDeck.removeFirst())

  case .ai:
    guard !state.aiDeck.isEmpty else { return }
    if state.aiHand.count >= CardDuelState.maxHandSize {
      state.aiDeck.removeFirst()
      return
    }
    state.aiHand.append(state.aiDeck.removeFirst())
  }
}

// MARK: - Spell Resolution

private func resolveSpell(
  effect: SpellEffect,
  caster: CardDuelState.TurnOwner,
  target: Target?,
  state: inout CardDuelState
) {
  let actorName = caster == .player ? "Player" : "AI"
  switch effect {

  case .damageTarget(let amount):
    guard let target else { return }
    switch target {
    case .enemyHero:
      let dmg = dealDamageToHero(
        amount: amount, side: caster == .player ? .ai : .player, state: &state)
      log(&state, "\(actorName)'s spell dealt \(dmg) to enemy hero.")
    case .friendlyHero:
      let dmg = dealDamageToHero(amount: amount, side: caster, state: &state)
      log(&state, "\(actorName)'s spell dealt \(dmg) to own hero.")
    case .minion(let id):
      if caster == .player {
        if let idx = state.aiBoard.firstIndex(where: { $0.id == id }) {
          dealDamageToMinion(amount: amount, index: idx, board: &state.aiBoard)
          log(&state, "\(actorName)'s spell dealt \(amount) to enemy minion.")
        }
      } else {
        if let idx = state.playerBoard.firstIndex(where: { $0.id == id }) {
          dealDamageToMinion(amount: amount, index: idx, board: &state.playerBoard)
          log(&state, "\(actorName)'s spell dealt \(amount) to friendly minion.")
        }
      }
    }

  case .healTarget(let amount):
    guard let target else { return }
    switch target {
    case .friendlyHero:
      let healed = healHero(amount: amount, side: caster, state: &state)
      log(&state, "\(actorName) healed hero for \(healed).")
    case .minion(let id):
      var board = caster == .player ? state.playerBoard : state.aiBoard
      if let idx = board.firstIndex(where: { $0.id == id }) {
        let actual = min(amount, board[idx].maxHealth - board[idx].currentHealth)
        board[idx].currentHealth += actual
        if caster == .player { state.playerBoard = board } else { state.aiBoard = board }
        log(&state, "\(actorName) healed minion for \(actual).")
      }
    case .enemyHero:
      return  // Healing enemy hero is not a valid play
    }

  case .healTarget: break  // handled above

  case .aoeEnemyMinions(let amount):
    let targetBoard = caster == .player ? state.aiBoard : state.playerBoard
    for i in targetBoard.indices {
      if caster == .player {
        dealDamageToMinion(amount: amount, index: i, board: &state.aiBoard)
      } else {
        dealDamageToMinion(amount: amount, index: i, board: &state.playerBoard)
      }
    }
    log(&state, "\(actorName)'s AOE dealt \(amount) to all enemy minions.")

  case .drawCards(let count):
    for _ in 0..<count { drawCard(for: caster, state: &state) }
    log(&state, "\(actorName) drew \(count) card(s).")

  case .buffMinion(let atkBuff, let hpBuff):
    guard let target, case .minion(let id) = target else { return }
    if caster == .player, let idx = state.playerBoard.firstIndex(where: { $0.id == id }) {
      state.playerBoard[idx].currentAttack += atkBuff
      state.playerBoard[idx].currentHealth += hpBuff
      log(&state, "\(actorName) buffed minion +\(atkBuff)/+\(hpBuff).")
    } else if caster == .ai, let idx = state.aiBoard.firstIndex(where: { $0.id == id }) {
      state.aiBoard[idx].currentAttack += atkBuff
      state.aiBoard[idx].currentHealth += hpBuff
      log(&state, "\(actorName) buffed minion +\(atkBuff)/+\(hpBuff).")
    }
  }
}

// MARK: - Damage & Healing

@discardableResult
private func dealDamageToHero(
  amount: Int, side: CardDuelState.TurnOwner, state: inout CardDuelState
) -> Int {
  let actual = max(0, amount)
  switch side {
  case .player:
    state.playerHP = max(0, state.playerHP - actual)
  case .ai:
    state.aiHP = max(0, state.aiHP - actual)
  }
  return actual
}

private func dealDamageToMinion(amount: Int, index: Int, board: inout [BoardMinion]) {
  guard board.indices.contains(index), amount > 0 else { return }
  if board[index].hasDivineShield {
    board[index].hasDivineShield = false  // Absorb and remove shield
    return
  }
  board[index].currentHealth -= amount
}

@discardableResult
private func healHero(amount: Int, side: CardDuelState.TurnOwner, state: inout CardDuelState) -> Int
{
  switch side {
  case .player:
    let healed = min(amount, CardDuelState.maxHP - state.playerHP)
    state.playerHP += healed
    return healed
  case .ai:
    let healed = min(amount, CardDuelState.maxHP - state.aiHP)
    state.aiHP += healed
    return healed
  }
}

// MARK: - Board Cleanup

private func removeDead(state: inout CardDuelState) {
  state.playerBoard.removeAll { $0.currentHealth <= 0 }
  state.aiBoard.removeAll { $0.currentHealth <= 0 }
}

// MARK: - Win Condition

@discardableResult
private func checkGameOver(state: inout CardDuelState) -> Bool {
  guard state.playerHP <= 0 || state.aiHP <= 0 else { return false }
  state.isRunning = false
  state.isGameOver = true
  if state.aiHP <= 0, state.playerHP > 0 {
    log(&state, "You win!")
  } else if state.playerHP <= 0, state.aiHP > 0 {
    log(&state, "AI wins.")
  } else {
    log(&state, "Draw.")
  }
  updateScore(state: &state)
  return true
}

// MARK: - Score & Log

private func updateScore(state: inout CardDuelState) {
  let winBonus = (state.aiHP <= 0 && state.playerHP > 0) ? 100 : 0
  state.score = max(0, (CardDuelState.maxHP - state.aiHP) * 10) + state.playerHP * 3 + winBonus
}

private func log(_ state: inout CardDuelState, _ entry: String) {
  state.battleLog.append(entry)
  if state.battleLog.count > 30 { state.battleLog.removeFirst(state.battleLog.count - 30) }
}
