/// Protocol that all game states must conform to.
/// Provides the minimum interface needed by the engine.
public protocol GameState: Sendable, Equatable {
    /// Whether the game is currently active (not paused, not game-over).
    var isRunning: Bool { get }

    /// Current score.
    var score: Int { get }

    /// Whether the game has ended.
    var isGameOver: Bool { get }
}
