import CoreEngine

/// Pure reducer for snake game logic.
public let snakeReducer: Reduce<SnakeState, SnakeAction> = { state, action in
    var newState = state
    switch action {
    case .tick:
        // TODO: Move snake, check collisions, check food
        break
    case .changeDirection(let direction):
        newState.direction = direction
    case .start:
        newState.isRunning = true
    case .pause:
        newState.isRunning = false
    case .reset:
        newState = SnakeState(gridWidth: state.gridWidth, gridHeight: state.gridHeight)
    }
    return (newState, .none)
}
