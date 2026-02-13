import CoreEngine

/// State of a memory card matching game session.
public struct MemoryMatchState: GameState, Equatable, Sendable {
    /// Number of card pairs.
    public let pairCount: Int

    /// All cards in the game.
    public var cards: [Card]

    /// Indices of currently flipped (face-up) cards.
    public var flippedIndices: [Int]

    /// Number of matched pairs found.
    public var matchedPairs: Int

    /// Number of moves (each flip-pair is one move).
    public var moves: Int

    /// Current score.
    public var score: Int

    /// Whether the game is running.
    public var isRunning: Bool

    /// Whether all pairs have been matched.
    public var isGameOver: Bool

    public init(pairCount: Int = 8) {
        self.pairCount = pairCount
        self.cards = []
        self.flippedIndices = []
        self.matchedPairs = 0
        self.moves = 0
        self.score = 0
        self.isRunning = false
        self.isGameOver = false
    }
}

/// A card in the memory match game.
public struct Card: Equatable, Sendable, Identifiable {
    public let id: Int
    /// Symbol identifier — cards with the same symbol are a pair.
    public let symbolID: Int
    /// Whether this card is face-up.
    public var isFaceUp: Bool = false
    /// Whether this card has been matched.
    public var isMatched: Bool = false

    public init(id: Int, symbolID: Int) {
        self.id = id
        self.symbolID = symbolID
    }
}
