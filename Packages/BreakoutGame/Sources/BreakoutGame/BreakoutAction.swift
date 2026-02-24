import CoreEngine

/// Actions for the breakout game.
public enum BreakoutAction: Sendable {
    case tick(deltaTime: Double)
    case movePaddle(x: Float)
    case launch
    case start
    case pause
    case resume
    case reset
}
