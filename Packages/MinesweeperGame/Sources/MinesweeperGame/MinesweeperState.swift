import CoreEngine

/// State of a minesweeper game session.
public struct MinesweeperState: GameState, Equatable, Sendable {
    /// Grid dimensions.
    public let rows: Int
    public let cols: Int
    /// Total number of mines.
    public let mineCount: Int

    /// Cell data.
    public var cells: [[Cell]]

    /// Number of flags placed.
    public var flagCount: Int

    /// Current score (time-based or click-based).
    public var score: Int

    /// Whether the game is running.
    public var isRunning: Bool

    /// Whether the game has ended.
    public var isGameOver: Bool

    /// Whether the player won.
    public var didWin: Bool

    public init(rows: Int = 9, cols: Int = 9, mineCount: Int = 10) {
        self.rows = rows
        self.cols = cols
        self.mineCount = mineCount
        self.cells = Array(
            repeating: Array(repeating: Cell(), count: cols),
            count: rows
        )
        self.flagCount = 0
        self.score = 0
        self.isRunning = false
        self.isGameOver = false
        self.didWin = false
    }
}

/// A single cell in the minesweeper grid.
public struct Cell: Equatable, Sendable {
    public var isMine: Bool = false
    public var isRevealed: Bool = false
    public var isFlagged: Bool = false
    public var adjacentMines: Int = 0
}
