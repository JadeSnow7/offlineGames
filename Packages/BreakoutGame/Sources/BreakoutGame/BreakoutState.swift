import CoreEngine

/// State of a breakout/brick-breaker game session.
public struct BreakoutState: GameState, Equatable, Sendable {
    /// Paddle position (center X, normalized 0..1).
    public var paddleX: Float

    /// Ball position and velocity.
    public var ball: Ball

    /// Remaining bricks.
    public var bricks: [Brick]

    /// Whether the ball has been launched from paddle.
    public var isBallLaunched: Bool

    /// Lives remaining.
    public var lives: Int

    /// Current score.
    public var score: Int

    /// Whether the game is running.
    public var isRunning: Bool

    /// Whether the game has ended.
    public var isGameOver: Bool

    public init() {
        self.paddleX = 0.5
        self.ball = Ball(x: 0.5, y: 0.8, vx: 0.3, vy: -0.4)
        self.bricks = BreakoutState.makeInitialBricks()
        self.isBallLaunched = false
        self.lives = 3
        self.score = 0
        self.isRunning = false
        self.isGameOver = false
    }

    private static func makeInitialBricks(rows: Int = 5, cols: Int = 8) -> [Brick] {
        var bricks: [Brick] = []
        bricks.reserveCapacity(rows * cols)
        var id = 0

        for row in 0..<rows {
            for col in 0..<cols {
                bricks.append(Brick(id: id, row: row, col: col, hitPoints: 1))
                id += 1
            }
        }

        return bricks
    }
}

/// A ball in the breakout game.
public struct Ball: Equatable, Sendable {
    public var x: Float
    public var y: Float
    public var vx: Float
    public var vy: Float

    public init(x: Float, y: Float, vx: Float, vy: Float) {
        self.x = x; self.y = y; self.vx = vx; self.vy = vy
    }
}

/// A brick in the breakout game.
public struct Brick: Equatable, Sendable, Identifiable {
    public let id: Int
    public let row: Int
    public let col: Int
    public var hitPoints: Int

    public init(id: Int, row: Int, col: Int, hitPoints: Int = 1) {
        self.id = id; self.row = row; self.col = col; self.hitPoints = hitPoints
    }
}
