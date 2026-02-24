import Testing
@testable import SnakeGame

@Test func snakeCannotReverseDirection() {
    let state = SnakeState()
    let (next, _) = snakeReducer(state, .changeDirection(.left))
    #expect(next.direction == .right)
}

@Test func snakeEatsFoodAndScores() {
    var state = SnakeState(gridWidth: 8, gridHeight: 8)
    state.isRunning = true
    state.segments = [
        GridPosition(x: 3, y: 3),
        GridPosition(x: 2, y: 3),
        GridPosition(x: 1, y: 3)
    ]
    state.direction = .right
    state.food = GridPosition(x: 4, y: 3)

    let (next, _) = snakeReducer(state, .tick)

    #expect(next.score == 10)
    #expect(next.segments.count == state.segments.count + 1)
    #expect(next.segments.first == GridPosition(x: 4, y: 3))
}

@Test func snakeHitsWallAndEndsGame() {
    var state = SnakeState(gridWidth: 5, gridHeight: 5)
    state.isRunning = true
    state.segments = [GridPosition(x: 4, y: 2)]
    state.direction = .right

    let (next, _) = snakeReducer(state, .tick)

    #expect(next.isGameOver)
    #expect(!next.isRunning)
}
