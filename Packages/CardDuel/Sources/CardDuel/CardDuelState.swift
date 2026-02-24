import CoreEngine

/// A minion that currently occupies a board slot.
public struct BoardMinion: Identifiable, Equatable, Sendable {
  public let id: Int  // Matches the spawning DuelCard's id
  public let card: DuelCard  // Original card data (for name, cost, etc.)
  public var currentAttack: Int
  public var currentHealth: Int
  public let maxHealth: Int
  /// False on the summon turn unless the minion has Rush or Charge.
  public var canAttack: Bool
  public var hasDivineShield: Bool
  public var summonedThisTurn: Bool  // Used to enforce Rush (can't hit hero until next turn)

  public init(from card: DuelCard, id: Int) {
    self.id = id
    self.card = card
    self.currentAttack = card.attack
    self.currentHealth = card.health
    self.maxHealth = card.health
    self.hasDivineShield = card.keywords.contains(.divineShield)
    self.summonedThisTurn = true
    // Rush → can attack minions now; Charge → can attack anything now
    self.canAttack = card.keywords.contains(.charge) || card.keywords.contains(.rush)
  }
}

/// Complete game state for one Card Duel CCG session.
public struct CardDuelState: GameState, Equatable, Sendable {
  public enum TurnOwner: String, Sendable, Equatable {
    case player
    case ai
  }

  public enum TurnPhase: Sendable, Equatable {
    case playerMain  // Player plays cards / attacks with minions
    case aiPlay  // AI plays cards
    case aiAttack  // AI orders minion attacks
  }

  // Constants
  public static let maxHP = 30
  public static let initialHandSize = 3
  public static let drawPerTurn = 1
  public static let maxHandSize = 7
  public static let maxBoardSize = 7
  public static let deckSize = 18
  public static let maxMana = 10

  public let seed: UInt64

  // Hero health
  public var playerHP: Int
  public var aiHP: Int

  // Decks and hands
  public var playerDeck: [DuelCard]
  public var aiDeck: [DuelCard]
  public var playerHand: [DuelCard]
  public var aiHand: [DuelCard]

  // Boards (ordered, append-only, max 7 each)
  public var playerBoard: [BoardMinion]
  public var aiBoard: [BoardMinion]

  // Mana
  public var playerMana: Int
  public var playerMaxMana: Int
  public var aiMana: Int
  public var aiMaxMana: Int

  // Turn tracking
  public var turnOwner: TurnOwner
  public var turnPhase: TurnPhase
  public var turnNumber: Int

  // Session
  public var isRunning: Bool
  public var score: Int
  public var isGameOver: Bool
  public var battleLog: [String]
  public var rng: SeededRNG

  public init(seed: UInt64 = SeededRNG.systemSeed()) {
    self.seed = seed
    self.playerHP = Self.maxHP
    self.aiHP = Self.maxHP
    self.playerDeck = []
    self.aiDeck = []
    self.playerHand = []
    self.aiHand = []
    self.playerBoard = []
    self.aiBoard = []
    self.playerMana = 0
    self.playerMaxMana = 0
    self.aiMana = 0
    self.aiMaxMana = 0
    self.turnOwner = .player
    self.turnPhase = .playerMain
    self.turnNumber = 0
    self.isRunning = false
    self.score = 0
    self.isGameOver = false
    self.battleLog = []
    self.rng = SeededRNG(seed: seed)
  }
}
