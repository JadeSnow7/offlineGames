import CoreEngine

/// Pure reducer for memory match game logic.
public let memoryMatchReducer: Reduce<MemoryMatchState, MemoryMatchAction> = { state, action in
    var newState = state
    switch action {
    case .flipCard(let index):
        guard !newState.cards[index].isMatched,
              !newState.cards[index].isFaceUp,
              newState.flippedIndices.count < 2
        else { break }
        newState.cards[index].isFaceUp = true
        newState.flippedIndices.append(index)
    case .checkMatch:
        guard newState.flippedIndices.count == 2 else { break }
        let i = newState.flippedIndices[0]
        let j = newState.flippedIndices[1]
        if newState.cards[i].symbolID == newState.cards[j].symbolID {
            newState.cards[i].isMatched = true
            newState.cards[j].isMatched = true
            newState.matchedPairs += 1
            newState.score += 100
        }
        newState.moves += 1
    case .hideUnmatched:
        for idx in newState.flippedIndices {
            if !newState.cards[idx].isMatched {
                newState.cards[idx].isFaceUp = false
            }
        }
        newState.flippedIndices.removeAll()
        newState.isGameOver = newState.matchedPairs == newState.pairCount
    case .start:
        newState.isRunning = true
    case .reset:
        newState = MemoryMatchState(pairCount: state.pairCount)
    }
    return (newState, .none)
}
