import Testing
@testable import MinesweeperGame

@Test func minesweeperFirstRevealIsSafe() {
    var state = MinesweeperState(rows: 9, cols: 9, mineCount: 10)
    state.isRunning = true

    let (next, _) = minesweeperReducer(state, .reveal(row: 0, col: 0))

    #expect(next.cells[0][0].isRevealed)
    #expect(!next.cells[0][0].isMine)
    #expect(!next.isGameOver)
}

@Test func minesweeperToggleFlagUpdatesCount() {
    var state = MinesweeperState(rows: 9, cols: 9, mineCount: 10)
    state.isRunning = true

    let (flagged, _) = minesweeperReducer(state, .toggleFlag(row: 1, col: 1))
    let (unflagged, _) = minesweeperReducer(flagged, .toggleFlag(row: 1, col: 1))

    #expect(flagged.cells[1][1].isFlagged)
    #expect(flagged.flagCount == 1)
    #expect(!unflagged.cells[1][1].isFlagged)
    #expect(unflagged.flagCount == 0)
}

@Test func minesweeperRevealMineEndsGame() {
    var state = MinesweeperState(rows: 5, cols: 5, mineCount: 3)
    state.isRunning = true
    state.cells[2][2].isMine = true

    let (next, _) = minesweeperReducer(state, .reveal(row: 2, col: 2))

    #expect(next.isGameOver)
    #expect(!next.isRunning)
    #expect(!next.didWin)
}
