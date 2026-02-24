import CoreEngine

/// Pure reducer for memory match game logic.
public let memoryMatchReducer: Reduce<MemoryMatchState, MemoryMatchAction> = { state, action in
    var newState = state

    switch action {
    case .flipCard(let index):
        guard newState.isRunning, !newState.isGameOver else { break }
        guard newState.cards.indices.contains(index) else { break }
        guard !newState.cards[index].isMatched,
              !newState.cards[index].isFaceUp,
              newState.flippedIndices.count < 2
        else { break }

        newState.cards[index].isFaceUp = true
        newState.flippedIndices.append(index)

        if newState.flippedIndices.count == 2 {
            newState.moves += 1
            let i = newState.flippedIndices[0]
            let j = newState.flippedIndices[1]

            if newState.cards[i].symbolID == newState.cards[j].symbolID {
                newState.cards[i].isMatched = true
                newState.cards[j].isMatched = true
                newState.matchedPairs += 1
                newState.score += 100
                newState.flippedIndices.removeAll()

                if newState.matchedPairs == newState.pairCount {
                    newState.isGameOver = true
                    newState.isRunning = false
                }
            }
        }

    case .checkMatch:
        // Matching is resolved immediately on second flip.
        break

    case .hideUnmatched:
        guard newState.flippedIndices.count == 2 else { break }
        for idx in newState.flippedIndices where !newState.cards[idx].isMatched {
            newState.cards[idx].isFaceUp = false
        }
        newState.flippedIndices.removeAll()

    case .start:
        if newState.cards.isEmpty || newState.isGameOver {
            newState = MemoryMatchState(pairCount: state.pairCount)
            newState.cards = makeDeck(pairCount: state.pairCount)
        }
        newState.isRunning = true

    case .pause:
        newState.isRunning = false

    case .resume:
        if !newState.isGameOver {
            newState.isRunning = true
        }

    case .reset:
        newState = MemoryMatchState(pairCount: state.pairCount)
    }

    return (newState, .none)
}

private func makeDeck(pairCount: Int) -> [Card] {
    var cards: [Card] = []
    cards.reserveCapacity(pairCount * 2)

    var id = 0
    for symbol in 0..<pairCount {
        cards.append(Card(id: id, symbolID: symbol))
        id += 1
        cards.append(Card(id: id, symbolID: symbol))
        id += 1
    }

    cards.shuffle()
    return cards
}
