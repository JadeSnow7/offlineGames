import CoreEngine

/// Actions for the block puzzle game.
public enum BlockPuzzleAction: Sendable {
    case tick
    case moveLeft
    case moveRight
    case rotate
    case softDrop
    case hardDrop
    case start
    case pause
    case reset
}
