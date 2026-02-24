/// A card in the Card Duel CCG system.
public struct DuelCard: Identifiable, Equatable, Sendable {
  public enum CardType: String, Sendable, Equatable {
    case minion  // Persists on the board after being played
    case spell  // Resolves immediately and goes to discard
  }

  public let id: Int
  /// Localization key for the card name.
  public let nameKey: String
  public let cardType: CardType
  /// Mana cost to play this card.
  public let cost: Int
  /// Attack power (minions only; 0 for spells).
  public let attack: Int
  /// Maximum health (minions only; 0 for spells).
  public let health: Int
  /// Special keyword abilities (minions only).
  public let keywords: [Keyword]
  /// Effect that resolves when a spell is played (nil for minions).
  public let spellEffect: SpellEffect?

  public init(
    id: Int,
    nameKey: String,
    cardType: CardType,
    cost: Int,
    attack: Int = 0,
    health: Int = 0,
    keywords: [Keyword] = [],
    spellEffect: SpellEffect? = nil
  ) {
    self.id = id
    self.nameKey = nameKey
    self.cardType = cardType
    self.cost = cost
    self.attack = attack
    self.health = health
    self.keywords = keywords
    self.spellEffect = spellEffect
  }
}
