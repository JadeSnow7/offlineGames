import CoreEngine

/// Pure reducer for block puzzle game logic.
public let blockPuzzleReducer: Reduce<BlockPuzzleState, BlockPuzzleAction> = { state, action in
    var newState = state

    switch action {
    case .tick:
        guard newState.isRunning, !newState.isGameOver else { break }
        ensurePieces(&newState)
        stepDown(&newState, rewardForSoftDrop: 0)

    case .moveLeft:
        guard newState.isRunning, !newState.isGameOver else { break }
        guard let current = newState.currentPiece else { break }
        var moved = current
        moved.x -= 1
        if canPlace(moved, in: newState.grid) {
            newState.currentPiece = moved
        }

    case .moveRight:
        guard newState.isRunning, !newState.isGameOver else { break }
        guard let current = newState.currentPiece else { break }
        var moved = current
        moved.x += 1
        if canPlace(moved, in: newState.grid) {
            newState.currentPiece = moved
        }

    case .rotate:
        guard newState.isRunning, !newState.isGameOver else { break }
        guard let current = newState.currentPiece else { break }

        let rotated = rotate(piece: current)
        if canPlace(rotated, in: newState.grid) {
            newState.currentPiece = rotated
        }

    case .softDrop:
        guard newState.isRunning, !newState.isGameOver else { break }
        ensurePieces(&newState)
        stepDown(&newState, rewardForSoftDrop: 1)

    case .hardDrop:
        guard newState.isRunning, !newState.isGameOver else { break }
        ensurePieces(&newState)
        hardDrop(&newState)

    case .start:
        if newState.isGameOver {
            newState = BlockPuzzleState(gridWidth: state.gridWidth, gridHeight: state.gridHeight)
        }
        newState.isRunning = true
        ensurePieces(&newState)

    case .pause:
        newState.isRunning = false

    case .resume:
        if !newState.isGameOver {
            newState.isRunning = true
        }

    case .reset:
        newState = BlockPuzzleState(gridWidth: state.gridWidth, gridHeight: state.gridHeight)
    }

    return (newState, .none)
}

private let pieceBlueprints: [(cells: [CellOffset], colorIndex: Int)] = [
    (cells: [CellOffset(dx: -1, dy: 0), CellOffset(dx: 0, dy: 0), CellOffset(dx: 1, dy: 0), CellOffset(dx: 2, dy: 0)], colorIndex: 1),
    (cells: [CellOffset(dx: -1, dy: 0), CellOffset(dx: 0, dy: 0), CellOffset(dx: 1, dy: 0), CellOffset(dx: 1, dy: 1)], colorIndex: 2),
    (cells: [CellOffset(dx: -1, dy: 0), CellOffset(dx: 0, dy: 0), CellOffset(dx: 1, dy: 0), CellOffset(dx: -1, dy: 1)], colorIndex: 3),
    (cells: [CellOffset(dx: 0, dy: 0), CellOffset(dx: 1, dy: 0), CellOffset(dx: 0, dy: 1), CellOffset(dx: 1, dy: 1)], colorIndex: 4),
    (cells: [CellOffset(dx: -1, dy: 0), CellOffset(dx: 0, dy: 0), CellOffset(dx: 0, dy: 1), CellOffset(dx: 1, dy: 1)], colorIndex: 5),
    (cells: [CellOffset(dx: -1, dy: 1), CellOffset(dx: 0, dy: 1), CellOffset(dx: 0, dy: 0), CellOffset(dx: 1, dy: 0)], colorIndex: 6),
    (cells: [CellOffset(dx: -1, dy: 0), CellOffset(dx: 0, dy: 0), CellOffset(dx: 1, dy: 0), CellOffset(dx: 0, dy: 1)], colorIndex: 7)
]

private func ensurePieces(_ state: inout BlockPuzzleState) {
    if state.nextPiece == nil {
        state.nextPiece = randomPiece(forWidth: state.gridWidth)
    }

    if state.currentPiece == nil {
        let next = state.nextPiece ?? randomPiece(forWidth: state.gridWidth)
        state.currentPiece = positioned(piece: next, forWidth: state.gridWidth)
        state.nextPiece = randomPiece(forWidth: state.gridWidth)

        if let current = state.currentPiece,
           !canPlace(current, in: state.grid) {
            state.isGameOver = true
            state.isRunning = false
        }
    }
}

private func stepDown(_ state: inout BlockPuzzleState, rewardForSoftDrop: Int) {
    guard var current = state.currentPiece else { return }

    var moved = current
    moved.y += 1

    if canPlace(moved, in: state.grid) {
        current = moved
        state.currentPiece = current
        state.score += rewardForSoftDrop
        return
    }

    lockCurrentPieceAndSpawnNext(state: &state)
}

private func hardDrop(_ state: inout BlockPuzzleState) {
    guard var current = state.currentPiece else { return }
    var dropDistance = 0

    while true {
        var candidate = current
        candidate.y += 1
        if canPlace(candidate, in: state.grid) {
            current = candidate
            dropDistance += 1
            continue
        }
        break
    }

    state.currentPiece = current
    state.score += dropDistance * 2
    lockCurrentPieceAndSpawnNext(state: &state)
}

private func lockCurrentPieceAndSpawnNext(state: inout BlockPuzzleState) {
    guard let current = state.currentPiece else { return }

    for (x, y) in occupiedCells(of: current) {
        guard y >= 0, y < state.gridHeight, x >= 0, x < state.gridWidth else { continue }
        state.grid[y][x] = current.colorIndex
    }

    let (newGrid, cleared) = clearFilledRows(grid: state.grid)
    state.grid = newGrid
    state.linesCleared += cleared
    state.score += scoreForClearedRows(cleared)

    let next = state.nextPiece ?? randomPiece(forWidth: state.gridWidth)
    state.currentPiece = positioned(piece: next, forWidth: state.gridWidth)
    state.nextPiece = randomPiece(forWidth: state.gridWidth)

    if let spawned = state.currentPiece,
       !canPlace(spawned, in: state.grid) {
        state.isGameOver = true
        state.isRunning = false
    }
}

private func randomPiece(forWidth width: Int) -> Piece {
    let blueprint = pieceBlueprints.randomElement() ?? pieceBlueprints[0]
    return positioned(piece: Piece(cells: blueprint.cells, colorIndex: blueprint.colorIndex), forWidth: width)
}

private func positioned(piece: Piece, forWidth width: Int) -> Piece {
    var positionedPiece = piece
    positionedPiece.x = width / 2
    positionedPiece.y = 0
    return positionedPiece
}

private func rotate(piece: Piece) -> Piece {
    var rotated = piece
    rotated.cells = piece.cells.map { cell in
        CellOffset(dx: -cell.dy, dy: cell.dx)
    }
    return rotated
}

private func canPlace(_ piece: Piece, in grid: [[Int]]) -> Bool {
    let height = grid.count
    guard let width = grid.first?.count else { return false }

    for (x, y) in occupiedCells(of: piece) {
        guard x >= 0, x < width, y >= 0, y < height else {
            return false
        }
        if grid[y][x] != 0 {
            return false
        }
    }

    return true
}

private func occupiedCells(of piece: Piece) -> [(Int, Int)] {
    piece.cells.map { offset in
        (piece.x + offset.dx, piece.y + offset.dy)
    }
}

private func clearFilledRows(grid: [[Int]]) -> ([[Int]], Int) {
    guard let width = grid.first?.count else { return (grid, 0) }

    let keptRows = grid.filter { row in
        row.contains(0)
    }
    let cleared = grid.count - keptRows.count
    let emptyRows = Array(repeating: Array(repeating: 0, count: width), count: cleared)

    return (emptyRows + keptRows, cleared)
}

private func scoreForClearedRows(_ count: Int) -> Int {
    switch count {
    case 0:
        return 0
    case 1:
        return 100
    case 2:
        return 250
    case 3:
        return 450
    default:
        return 700
    }
}
