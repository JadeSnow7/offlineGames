import Testing
@testable import MemoryMatch

@Test func memoryMatchStartCreatesDeck() {
    let state = MemoryMatchState(pairCount: 6)
    let (next, _) = memoryMatchReducer(state, .start)

    #expect(next.isRunning)
    #expect(next.cards.count == 12)
}

@Test func memoryMatchPairIncreasesScore() {
    var state = MemoryMatchState(pairCount: 1)
    state.isRunning = true
    state.cards = [Card(id: 0, symbolID: 7), Card(id: 1, symbolID: 7)]

    let (firstFlip, _) = memoryMatchReducer(state, .flipCard(index: 0))
    let (secondFlip, _) = memoryMatchReducer(firstFlip, .flipCard(index: 1))

    #expect(secondFlip.matchedPairs == 1)
    #expect(secondFlip.score == 100)
    #expect(secondFlip.isGameOver)
}

@Test func memoryMatchHideUnmatchedTurnsCardsBack() {
    var state = MemoryMatchState(pairCount: 2)
    state.isRunning = true
    state.cards = [
        Card(id: 0, symbolID: 1),
        Card(id: 1, symbolID: 2),
        Card(id: 2, symbolID: 1),
        Card(id: 3, symbolID: 2)
    ]

    let (firstFlip, _) = memoryMatchReducer(state, .flipCard(index: 0))
    let (secondFlip, _) = memoryMatchReducer(firstFlip, .flipCard(index: 1))
    let (hidden, _) = memoryMatchReducer(secondFlip, .hideUnmatched)

    #expect(!hidden.cards[0].isFaceUp)
    #expect(!hidden.cards[1].isFaceUp)
    #expect(hidden.flippedIndices.isEmpty)
}
