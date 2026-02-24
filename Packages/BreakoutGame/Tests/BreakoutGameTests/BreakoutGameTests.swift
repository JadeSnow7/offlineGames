import Testing
@testable import BreakoutGame

@Test func breakoutLaunchStartsBall() {
    var state = BreakoutState()
    state.isRunning = true

    let (next, _) = breakoutReducer(state, .launch)

    #expect(next.isBallLaunched)
}

@Test func breakoutLosesLifeWhenBallFalls() {
    var state = BreakoutState()
    state.isRunning = true
    state.isBallLaunched = true
    state.ball.y = 1.2

    let (next, _) = breakoutReducer(state, .tick(deltaTime: 0.016))

    #expect(next.lives == state.lives - 1)
    #expect(!next.isBallLaunched)
}

@Test func breakoutEndsWhenNoBricksRemain() {
    var state = BreakoutState()
    state.isRunning = true
    state.isBallLaunched = true
    state.bricks = []

    let (next, _) = breakoutReducer(state, .tick(deltaTime: 0.016))

    #expect(next.isGameOver)
    #expect(!next.isRunning)
}
