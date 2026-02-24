import CoreEngine

/// Pure reducer for breakout game logic.
public let breakoutReducer: Reduce<BreakoutState, BreakoutAction> = { state, action in
    var newState = state

    switch action {
    case .tick(let dt):
        guard newState.isRunning, !newState.isGameOver else { break }

        if !newState.isBallLaunched {
            parkBallOnPaddle(&newState)
            break
        }

        stepBall(&newState, deltaTime: dt)
        handleWallCollisions(&newState)
        handlePaddleCollision(&newState)
        handleBrickCollision(&newState)
        handleBottomOut(&newState)

        if newState.bricks.isEmpty {
            newState.isGameOver = true
            newState.isRunning = false
            newState.score += 500
        }

    case .movePaddle(let x):
        newState.paddleX = min(max(x, 0.1), 0.9)
        if !newState.isBallLaunched {
            parkBallOnPaddle(&newState)
        }

    case .launch:
        guard newState.isRunning, !newState.isGameOver else { break }
        if !newState.isBallLaunched {
            newState.isBallLaunched = true
            newState.ball.vx = newState.ball.vx == 0 ? 0.35 : newState.ball.vx
            newState.ball.vy = -abs(newState.ball.vy == 0 ? 0.45 : newState.ball.vy)
        }

    case .start:
        if newState.isGameOver {
            newState = BreakoutState()
        }
        newState.isRunning = true

    case .pause:
        newState.isRunning = false

    case .resume:
        if !newState.isGameOver {
            newState.isRunning = true
        }

    case .reset:
        newState = BreakoutState()
    }

    return (newState, .none)
}

private let ballRadius: Float = 0.015
private let paddleWidth: Float = 0.22
private let paddleHeight: Float = 0.03
private let paddleY: Float = 0.92
private let brickCols: Int = 8
private let brickGap: Float = 0.008
private let brickTop: Float = 0.08
private let brickHeight: Float = 0.05

private func stepBall(_ state: inout BreakoutState, deltaTime: Double) {
    let clampedDelta = Float(min(max(deltaTime, 0.0), 0.05))
    state.ball.x += state.ball.vx * clampedDelta
    state.ball.y += state.ball.vy * clampedDelta
}

private func parkBallOnPaddle(_ state: inout BreakoutState) {
    state.ball.x = state.paddleX
    state.ball.y = paddleY - paddleHeight * 0.75
    state.ball.vy = -abs(state.ball.vy == 0 ? 0.45 : state.ball.vy)
}

private func handleWallCollisions(_ state: inout BreakoutState) {
    if state.ball.x - ballRadius <= 0 {
        state.ball.x = ballRadius
        state.ball.vx = abs(state.ball.vx)
    }

    if state.ball.x + ballRadius >= 1 {
        state.ball.x = 1 - ballRadius
        state.ball.vx = -abs(state.ball.vx)
    }

    if state.ball.y - ballRadius <= 0 {
        state.ball.y = ballRadius
        state.ball.vy = abs(state.ball.vy)
    }
}

private func handlePaddleCollision(_ state: inout BreakoutState) {
    guard state.ball.vy > 0 else { return }

    let halfWidth = paddleWidth / 2
    let paddleLeft = state.paddleX - halfWidth
    let paddleRight = state.paddleX + halfWidth
    let paddleTop = paddleY - paddleHeight / 2

    let hitsX = state.ball.x >= paddleLeft - ballRadius && state.ball.x <= paddleRight + ballRadius
    let hitsY = state.ball.y + ballRadius >= paddleTop && state.ball.y <= paddleY + paddleHeight

    guard hitsX, hitsY else { return }

    let offset = (state.ball.x - state.paddleX) / halfWidth
    state.ball.x = min(max(state.ball.x, paddleLeft + ballRadius), paddleRight - ballRadius)
    state.ball.y = paddleTop - ballRadius
    state.ball.vy = -abs(state.ball.vy)
    state.ball.vx = min(max(state.ball.vx + offset * 0.25, -0.75), 0.75)
}

private func handleBrickCollision(_ state: inout BreakoutState) {
    let brickWidth = (1 - brickGap * Float(brickCols + 1)) / Float(brickCols)
    var hitIndex: Int?

    for (index, brick) in state.bricks.enumerated() {
        let x = brickGap + Float(brick.col) * (brickWidth + brickGap)
        let y = brickTop + Float(brick.row) * (brickHeight + brickGap)

        let centerX = x + brickWidth / 2
        let centerY = y + brickHeight / 2
        let intersectsX = abs(state.ball.x - centerX) <= brickWidth / 2 + ballRadius
        let intersectsY = abs(state.ball.y - centerY) <= brickHeight / 2 + ballRadius

        guard intersectsX, intersectsY else { continue }
        hitIndex = index
        break
    }

    guard let hitIndex else { return }

    state.bricks[hitIndex].hitPoints -= 1
    if state.bricks[hitIndex].hitPoints <= 0 {
        state.bricks.remove(at: hitIndex)
        state.score += 50
    }

    state.ball.vy *= -1
}

private func handleBottomOut(_ state: inout BreakoutState) {
    guard state.ball.y - ballRadius > 1 else { return }

    state.lives -= 1

    if state.lives <= 0 {
        state.isGameOver = true
        state.isRunning = false
        state.isBallLaunched = false
        return
    }

    state.isBallLaunched = false
    state.ball.vx = state.ball.vx >= 0 ? 0.35 : -0.35
    state.ball.vy = -0.45
    parkBallOnPaddle(&state)
}
