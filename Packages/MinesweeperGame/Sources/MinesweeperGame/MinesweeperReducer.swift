import CoreEngine

/// Pure reducer for minesweeper game logic.
public let minesweeperReducer: Reduce<MinesweeperState, MinesweeperAction> = { state, action in
    var newState = state
    switch action {
    case .reveal(let row, let col):
        // TODO: Reveal cell, flood-fill if zero adjacent, check mine
        _ = (row, col)
        break
    case .toggleFlag(let row, let col):
        guard !newState.cells[row][col].isRevealed else { break }
        newState.cells[row][col].isFlagged.toggle()
        newState.flagCount += newState.cells[row][col].isFlagged ? 1 : -1
    case .start:
        newState.isRunning = true
    case .reset:
        newState = MinesweeperState(rows: state.rows, cols: state.cols, mineCount: state.mineCount)
    }
    return (newState, .none)
}
