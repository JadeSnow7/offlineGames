import CoreEngine

/// Pure reducer for block puzzle game logic.
public let blockPuzzleReducer: Reduce<BlockPuzzleState, BlockPuzzleAction> = { state, action in
    var newState = state
    switch action {
    case .tick:
        // TODO: Drop piece one row, check landing, clear lines
        break
    case .moveLeft:
        newState.currentPiece?.x -= 1
    case .moveRight:
        newState.currentPiece?.x += 1
    case .rotate:
        // TODO: Rotate current piece with wall-kick
        break
    case .softDrop:
        newState.currentPiece?.y += 1
    case .hardDrop:
        // TODO: Instant drop to bottom
        break
    case .start:
        newState.isRunning = true
    case .pause:
        newState.isRunning = false
    case .reset:
        newState = BlockPuzzleState(gridWidth: state.gridWidth, gridHeight: state.gridHeight)
    }
    return (newState, .none)
}
