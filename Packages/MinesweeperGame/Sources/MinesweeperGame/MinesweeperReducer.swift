import CoreEngine

/// Pure reducer for minesweeper game logic.
public let minesweeperReducer: Reduce<MinesweeperState, MinesweeperAction> = { state, action in
    var newState = state

    switch action {
    case .reveal(let row, let col):
        guard isInBounds(row: row, col: col, rows: newState.rows, cols: newState.cols) else { break }
        guard newState.isRunning, !newState.isGameOver else { break }
        guard !newState.cells[row][col].isFlagged, !newState.cells[row][col].isRevealed else { break }

        if !hasAnyMines(in: newState.cells) {
            placeMines(in: &newState, excludingRow: row, excludingCol: col)
            computeAdjacentCounts(in: &newState)
        }

        if newState.cells[row][col].isMine {
            newState.cells[row][col].isRevealed = true
            revealAllMines(in: &newState)
            newState.isGameOver = true
            newState.isRunning = false
            newState.didWin = false
            break
        }

        let revealedCount = floodReveal(fromRow: row, col: col, in: &newState)
        newState.score += revealedCount * 10

        if hasClearedAllSafeCells(state: newState) {
            newState.didWin = true
            newState.isGameOver = true
            newState.isRunning = false
            newState.score += 500
        }

    case .toggleFlag(let row, let col):
        guard isInBounds(row: row, col: col, rows: newState.rows, cols: newState.cols) else { break }
        guard newState.isRunning, !newState.isGameOver else { break }
        guard !newState.cells[row][col].isRevealed else { break }

        newState.cells[row][col].isFlagged.toggle()
        newState.flagCount += newState.cells[row][col].isFlagged ? 1 : -1

    case .start:
        if newState.isGameOver {
            newState = MinesweeperState(rows: state.rows, cols: state.cols, mineCount: state.mineCount)
        }
        newState.isRunning = true

    case .pause:
        newState.isRunning = false

    case .resume:
        if !newState.isGameOver {
            newState.isRunning = true
        }

    case .reset:
        newState = MinesweeperState(rows: state.rows, cols: state.cols, mineCount: state.mineCount)
    }

    return (newState, .none)
}

private func isInBounds(row: Int, col: Int, rows: Int, cols: Int) -> Bool {
    row >= 0 && row < rows && col >= 0 && col < cols
}

private func hasAnyMines(in cells: [[Cell]]) -> Bool {
    for row in cells {
        if row.contains(where: { $0.isMine }) {
            return true
        }
    }
    return false
}

private func placeMines(in state: inout MinesweeperState, excludingRow: Int, excludingCol: Int) {
    var positions: [(Int, Int)] = []

    for row in 0..<state.rows {
        for col in 0..<state.cols {
            if row == excludingRow && col == excludingCol {
                continue
            }
            positions.append((row, col))
        }
    }

    positions.shuffle()

    let count = min(state.mineCount, positions.count)
    for index in 0..<count {
        let (row, col) = positions[index]
        state.cells[row][col].isMine = true
    }
}

private func computeAdjacentCounts(in state: inout MinesweeperState) {
    for row in 0..<state.rows {
        for col in 0..<state.cols {
            guard !state.cells[row][col].isMine else { continue }
            state.cells[row][col].adjacentMines = neighborPositions(row: row, col: col, rows: state.rows, cols: state.cols)
                .reduce(into: 0) { result, position in
                    if state.cells[position.0][position.1].isMine {
                        result += 1
                    }
                }
        }
    }
}

private func floodReveal(fromRow row: Int, col: Int, in state: inout MinesweeperState) -> Int {
    var queue: [(Int, Int)] = [(row, col)]
    var revealedCount = 0

    while !queue.isEmpty {
        let (currentRow, currentCol) = queue.removeFirst()

        guard isInBounds(row: currentRow, col: currentCol, rows: state.rows, cols: state.cols) else {
            continue
        }

        if state.cells[currentRow][currentCol].isRevealed || state.cells[currentRow][currentCol].isFlagged {
            continue
        }

        state.cells[currentRow][currentCol].isRevealed = true
        revealedCount += 1

        if state.cells[currentRow][currentCol].adjacentMines == 0 {
            queue.append(contentsOf: neighborPositions(row: currentRow, col: currentCol, rows: state.rows, cols: state.cols))
        }
    }

    return revealedCount
}

private func neighborPositions(row: Int, col: Int, rows: Int, cols: Int) -> [(Int, Int)] {
    var neighbors: [(Int, Int)] = []

    for deltaRow in -1...1 {
        for deltaCol in -1...1 {
            if deltaRow == 0 && deltaCol == 0 {
                continue
            }

            let newRow = row + deltaRow
            let newCol = col + deltaCol
            if isInBounds(row: newRow, col: newCol, rows: rows, cols: cols) {
                neighbors.append((newRow, newCol))
            }
        }
    }

    return neighbors
}

private func revealAllMines(in state: inout MinesweeperState) {
    for row in 0..<state.rows {
        for col in 0..<state.cols {
            if state.cells[row][col].isMine {
                state.cells[row][col].isRevealed = true
            }
        }
    }
}

private func hasClearedAllSafeCells(state: MinesweeperState) -> Bool {
    for row in 0..<state.rows {
        for col in 0..<state.cols {
            let cell = state.cells[row][col]
            if !cell.isMine && !cell.isRevealed {
                return false
            }
        }
    }

    return true
}
