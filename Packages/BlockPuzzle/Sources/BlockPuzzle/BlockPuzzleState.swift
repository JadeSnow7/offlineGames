import CoreEngine

/// A cell offset relative to a piece pivot.
public struct CellOffset: Equatable, Sendable {
    public var dx: Int
    public var dy: Int

    public init(dx: Int, dy: Int) {
        self.dx = dx
        self.dy = dy
    }
}

/// State of a block puzzle game session.
/// Uses custom pentomino-style pieces to avoid IP issues.
public struct BlockPuzzleState: GameState, Equatable, Sendable {
    /// Grid dimensions (wider than standard to differentiate).
    public let gridWidth: Int
    public let gridHeight: Int

    /// The grid — 0 means empty, positive values are piece colors.
    public var grid: [[Int]]

    /// The currently falling piece.
    public var currentPiece: Piece?

    /// Next piece preview.
    public var nextPiece: Piece?

    /// Current score.
    public var score: Int

    /// Lines cleared.
    public var linesCleared: Int

    /// Whether the game is running.
    public var isRunning: Bool

    /// Whether the game has ended.
    public var isGameOver: Bool

    public init(gridWidth: Int = 12, gridHeight: Int = 24) {
        self.gridWidth = gridWidth
        self.gridHeight = gridHeight
        self.grid = Array(repeating: Array(repeating: 0, count: gridWidth), count: gridHeight)
        self.currentPiece = nil
        self.nextPiece = nil
        self.score = 0
        self.linesCleared = 0
        self.isRunning = false
        self.isGameOver = false
    }
}

/// A puzzle piece defined by relative cell offsets.
public struct Piece: Equatable, Sendable {
    /// Cell offsets relative to pivot.
    public let cells: [CellOffset]
    /// Color index.
    public let colorIndex: Int
    /// Position on the grid.
    public var x: Int
    public var y: Int

    public init(cells: [CellOffset], colorIndex: Int, x: Int = 0, y: Int = 0) {
        self.cells = cells
        self.colorIndex = colorIndex
        self.x = x
        self.y = y
    }
}
