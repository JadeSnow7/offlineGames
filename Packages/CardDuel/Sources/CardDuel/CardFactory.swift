/// Curated card pool and deck generation for Card Duel.
enum CardFactory {
  private struct CardTemplate {
    let nameKey: String
    let cardType: DuelCard.CardType
    let cost: Int
    let attack: Int
    let health: Int
    let keywords: [Keyword]
    let spellEffect: SpellEffect?

    init(
      _ nameKey: String,
      _ cardType: DuelCard.CardType,
      cost: Int,
      attack: Int = 0,
      health: Int = 0,
      keywords: [Keyword] = [],
      spell: SpellEffect? = nil
    ) {
      self.nameKey = nameKey
      self.cardType = cardType
      self.cost = cost
      self.attack = attack
      self.health = health
      self.keywords = keywords
      self.spellEffect = spell
    }
  }

  /// Fixed card pool — 13 distinct templates.
  private static let pool: [CardTemplate] = [
    // --- Low cost (1–3 mana) ---
    CardTemplate("card.scout", .minion, cost: 1, attack: 1, health: 2),
    CardTemplate("card.squire", .minion, cost: 2, attack: 2, health: 3),
    CardTemplate("card.guardian", .minion, cost: 2, attack: 1, health: 4, keywords: [.taunt]),
    CardTemplate("card.charger", .minion, cost: 3, attack: 3, health: 2, keywords: [.charge]),
    // --- Mid cost (4–6 mana) ---
    CardTemplate("card.knight", .minion, cost: 4, attack: 4, health: 5),
    CardTemplate(
      "card.paladin", .minion, cost: 5, attack: 3, health: 6, keywords: [.taunt, .divineShield]),
    CardTemplate("card.berserker", .minion, cost: 4, attack: 5, health: 3, keywords: [.rush]),
    // --- High cost (7+ mana) ---
    CardTemplate("card.dragon", .minion, cost: 7, attack: 7, health: 7, keywords: [.charge]),
    CardTemplate("card.titan", .minion, cost: 8, attack: 8, health: 8, keywords: [.taunt]),
    // --- Spells ---
    CardTemplate("card.fireball", .spell, cost: 4, spell: .damageTarget(6)),
    CardTemplate("card.heal", .spell, cost: 3, spell: .healTarget(8)),
    CardTemplate("card.nova", .spell, cost: 6, spell: .aoeEnemyMinions(3)),
    CardTemplate("card.wisdom", .spell, cost: 2, spell: .drawCards(2)),
  ]

  /// Generates a shuffled deck by randomly sampling from the pool with repetition.
  static func makeDeck(size: Int, startingID: Int, rng: inout SeededRNG) -> [DuelCard] {
    var cards: [DuelCard] = []
    cards.reserveCapacity(size)

    for offset in 0..<size {
      let templateIndex = rng.nextInt(in: 0...(pool.count - 1))
      let t = pool[templateIndex]
      cards.append(
        DuelCard(
          id: startingID + offset,
          nameKey: t.nameKey,
          cardType: t.cardType,
          cost: t.cost,
          attack: t.attack,
          health: t.health,
          keywords: t.keywords,
          spellEffect: t.spellEffect
        ))
    }

    // Fisher-Yates shuffle using the seeded RNG
    for i in stride(from: cards.count - 1, through: 1, by: -1) {
      let j = rng.nextInt(in: 0...i)
      if j != i { cards.swapAt(i, j) }
    }

    return cards
  }
}
