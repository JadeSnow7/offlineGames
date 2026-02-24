import CoreEngine

/// Pure reducer for snake game logic.
public let snakeReducer: Reduce<SnakeState, SnakeAction> = { state, action in
    var newState = state

    switch action {
    case .tick:
        guard newState.isRunning, !newState.isGameOver else { break }
        guard let head = newState.segments.first else {
            newState.isGameOver = true
            newState.isRunning = false
            break
        }

        let nextHead = moved(head: head, direction: newState.direction)
        guard isInsideBounds(nextHead, width: newState.gridWidth, height: newState.gridHeight) else {
            newState.isGameOver = true
            newState.isRunning = false
            break
        }

        if newState.segments.contains(nextHead) {
            newState.isGameOver = true
            newState.isRunning = false
            break
        }

        newState.segments.insert(nextHead, at: 0)

        if nextHead == newState.food {
            newState.score += 10
            newState.food = makeFood(excluding: newState.segments,
                                     width: newState.gridWidth,
                                     height: newState.gridHeight,
                                     fallback: newState.food)
        } else {
            _ = newState.segments.popLast()
        }

    case .changeDirection(let direction):
        guard !isOpposite(newState.direction, direction) else { break }
        newState.direction = direction

    case .start:
        if newState.isGameOver {
            newState = SnakeState(gridWidth: state.gridWidth, gridHeight: state.gridHeight)
        }
        newState.isRunning = true

    case .pause:
        newState.isRunning = false

    case .resume:
        if !newState.isGameOver {
            newState.isRunning = true
        }

    case .reset:
        newState = SnakeState(gridWidth: state.gridWidth, gridHeight: state.gridHeight)
    }

    return (newState, .none)
}

private func moved(head: GridPosition, direction: Direction) -> GridPosition {
    switch direction {
    case .up:
        return GridPosition(x: head.x, y: head.y - 1)
    case .down:
        return GridPosition(x: head.x, y: head.y + 1)
    case .left:
        return GridPosition(x: head.x - 1, y: head.y)
    case .right:
        return GridPosition(x: head.x + 1, y: head.y)
    }
}

private func isInsideBounds(_ position: GridPosition, width: Int, height: Int) -> Bool {
    position.x >= 0 && position.x < width && position.y >= 0 && position.y < height
}

private func isOpposite(_ lhs: Direction, _ rhs: Direction) -> Bool {
    switch (lhs, rhs) {
    case (.up, .down), (.down, .up), (.left, .right), (.right, .left):
        return true
    default:
        return false
    }
}

private func makeFood(excluding segments: [GridPosition], width: Int, height: Int, fallback: GridPosition) -> GridPosition {
    let occupied = Set(segments)
    var available: [GridPosition] = []
    available.reserveCapacity(width * height - occupied.count)

    for y in 0..<height {
        for x in 0..<width {
            let position = GridPosition(x: x, y: y)
            if !occupied.contains(position) {
                available.append(position)
            }
        }
    }

    return available.randomElement() ?? fallback
}
