import CoreEngine

/// Pure reducer for breakout game logic.
public let breakoutReducer: Reduce<BreakoutState, BreakoutAction> = { state, action in
    var newState = state
    switch action {
    case .tick(let dt):
        // TODO: Update ball position, check collisions with walls/paddle/bricks
        _ = dt
        break
    case .movePaddle(let x):
        newState.paddleX = min(max(x, 0), 1)
    case .launch:
        // TODO: Launch ball from paddle
        break
    case .start:
        newState.isRunning = true
    case .pause:
        newState.isRunning = false
    case .reset:
        newState = BreakoutState()
    }
    return (newState, .none)
}
