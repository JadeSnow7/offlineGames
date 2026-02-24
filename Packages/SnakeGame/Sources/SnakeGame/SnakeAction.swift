import CoreEngine

/// Actions for the snake game.
public enum SnakeAction: Sendable {
    /// Game tick — move the snake forward.
    case tick
    /// Change direction.
    case changeDirection(Direction)
    /// Start/resume the game.
    case start
    /// Pause the game.
    case pause
    /// Resume a paused game.
    case resume
    /// Reset to initial state.
    case reset
}
