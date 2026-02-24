/// Actions for the minesweeper game.
public enum MinesweeperAction: Sendable {
    case reveal(row: Int, col: Int)
    case toggleFlag(row: Int, col: Int)
    case start
    case pause
    case resume
    case reset
}
