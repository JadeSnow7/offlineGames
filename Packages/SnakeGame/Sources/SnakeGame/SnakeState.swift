import CoreEngine

/// A position on the game grid.
public struct GridPosition: Equatable, Sendable, Hashable {
    public var x: Int
    public var y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

/// State of a snake game session.
public struct SnakeState: GameState, Equatable, Sendable {
    /// Grid dimensions.
    public let gridWidth: Int
    public let gridHeight: Int

    /// Snake body segments as grid positions (head is first).
    public var segments: [GridPosition]

    /// Current movement direction.
    public var direction: Direction

    /// Food position on the grid.
    public var food: GridPosition

    /// Current score.
    public var score: Int

    /// Whether the game is running.
    public var isRunning: Bool

    /// Whether the game has ended.
    public var isGameOver: Bool

    public init(gridWidth: Int = 20, gridHeight: Int = 20) {
        self.gridWidth = gridWidth
        self.gridHeight = gridHeight
        self.segments = [GridPosition(x: 10, y: 10), GridPosition(x: 9, y: 10), GridPosition(x: 8, y: 10)]
        self.direction = .right
        self.food = GridPosition(x: 15, y: 10)
        self.score = 0
        self.isRunning = false
        self.isGameOver = false
    }
}
