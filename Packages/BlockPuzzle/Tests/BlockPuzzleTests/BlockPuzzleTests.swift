import Testing
@testable import BlockPuzzle

@Test func blockPuzzleStartSpawnsPiece() {
    let state = BlockPuzzleState()
    let (next, _) = blockPuzzleReducer(state, .start)

    #expect(next.isRunning)
    #expect(next.currentPiece != nil)
    #expect(next.nextPiece != nil)
}

@Test func blockPuzzleHardDropLocksPiece() {
    var state = BlockPuzzleState(gridWidth: 10, gridHeight: 10)
    let (started, _) = blockPuzzleReducer(state, .start)
    state = started

    let (next, _) = blockPuzzleReducer(state, .hardDrop)

    let hasLockedCells = next.grid.flatMap { $0 }.contains { $0 > 0 }
    #expect(hasLockedCells)
    #expect(next.currentPiece != nil)
}

@Test func blockPuzzleResumeFromPause() {
    var state = BlockPuzzleState()
    state.isRunning = true
    let (paused, _) = blockPuzzleReducer(state, .pause)
    let (resumed, _) = blockPuzzleReducer(paused, .resume)

    #expect(!paused.isRunning)
    #expect(resumed.isRunning)
}
