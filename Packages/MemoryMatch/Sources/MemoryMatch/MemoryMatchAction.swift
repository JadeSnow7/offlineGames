/// Actions for the memory match game.
public enum MemoryMatchAction: Sendable {
    case flipCard(index: Int)
    case checkMatch
    case hideUnmatched
    case start
    case reset
}
