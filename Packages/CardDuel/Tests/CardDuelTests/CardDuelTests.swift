import Testing
@testable import CardDuel

@Test func cardDuelStartInitializesHandsAndDecks() {
    let initial = CardDuelState(seed: 42)
    let (started, _) = cardDuelReducer(initial, .start)

    #expect(started.isRunning)
    #expect(!started.isGameOver)
    #expect(started.turnOwner == .player)
    #expect(started.playerHand.count == 3)
    #expect(started.aiHand.count == 3)
    #expect(started.playerDeck.count == 15)
    #expect(started.aiDeck.count == 15)
}

@Test func cardDuelDrawPerTurnAndBurnOnFullHand() {
    let initial = CardDuelState(seed: 8)
    let (started, _) = cardDuelReducer(initial, .start)
    let (drawn, _) = cardDuelReducer(started, .drawForCurrentTurn)

    #expect(drawn.playerHand.count == 4)
    #expect(drawn.playerDeck.count == 14)

    var fullHand = CardDuelState(seed: 8)
    fullHand.isRunning = true
    fullHand.turnOwner = .player
    fullHand.playerHand = (0..<CardDuelState.maxHandSize).map {
        testCard(id: $0, attribute: .flame, skill: .guard, baseValue: 3)
    }
    fullHand.playerDeck = [testCard(id: 999, attribute: .tide, skill: .strike, baseValue: 6)]

    let (burned, _) = cardDuelReducer(fullHand, .drawForCurrentTurn)
    #expect(burned.playerHand.count == CardDuelState.maxHandSize)
    #expect(burned.playerDeck.isEmpty)
}

@Test func cardDuelAttributeMultipliersFollowTriangle() {
    #expect(CardAttribute.flame.multiplier(against: .gale) == 1.5)
    #expect(CardAttribute.flame.multiplier(against: .tide) == 0.75)
    #expect(CardAttribute.flame.multiplier(against: .flame) == 1.0)
}

@Test func cardDuelShieldAbsorbsBeforeHP() {
    var state = CardDuelState(seed: 1)
    state.isRunning = true
    state.turnOwner = .player
    state.aiShield = 5
    state.aiHP = CardDuelState.maxHP

    let strike = testCard(id: 1, attribute: .flame, skill: .strike, baseValue: 8)
    let (resolved, _) = cardDuelReducer(state, .resolveCard(owner: .player, card: strike))

    #expect(resolved.aiShield == 0)
    #expect(resolved.aiHP == 27)
}

@Test func cardDuelHealDoesNotExceedMaxHP() {
    var state = CardDuelState(seed: 1)
    state.isRunning = true
    state.turnOwner = .player
    state.playerHP = 28

    let mend = testCard(id: 2, attribute: .tide, skill: .mend, baseValue: 6)
    let (resolved, _) = cardDuelReducer(state, .resolveCard(owner: .player, card: mend))

    #expect(resolved.playerHP == CardDuelState.maxHP)
}

@Test func cardDuelInsightDrawsCardEvenInResolve() {
    var state = CardDuelState(seed: 1)
    state.isRunning = true
    state.turnOwner = .player
    state.playerDeck = [testCard(id: 100, attribute: .gale, skill: .guard, baseValue: 5)]

    let insight = testCard(id: 3, attribute: .flame, skill: .insight, baseValue: 2)
    let (resolved, _) = cardDuelReducer(state, .resolveCard(owner: .player, card: insight))

    #expect(resolved.playerDeck.isEmpty)
    #expect(resolved.playerHand.count == 1)
}

@Test func cardDuelPierceTrueDamageIgnoresShieldAndMultiplier() {
    var state = CardDuelState(seed: 1)
    state.isRunning = true
    state.turnOwner = .player
    state.aiHP = 10
    state.aiShield = 10
    state.aiStance = .tide

    let pierce = testCard(id: 4, attribute: .flame, skill: .pierce, baseValue: 4)
    let (resolved, _) = cardDuelReducer(state, .resolveCard(owner: .player, card: pierce))

    #expect(resolved.aiHP == 8)
    #expect(resolved.aiShield == 7)
}

@Test func cardDuelAIPrioritizesLethalCard() {
    var state = CardDuelState(seed: 1)
    state.isRunning = true
    state.turnOwner = .ai
    state.playerHP = 4
    state.playerShield = 0
    state.aiHP = CardDuelState.maxHP
    state.aiHand = [
        testCard(id: 5, attribute: .tide, skill: .mend, baseValue: 6),
        testCard(id: 6, attribute: .gale, skill: .strike, baseValue: 4)
    ]

    let index = CardDuelAI.chooseCardIndex(state: state)
    #expect(index == 1)
}

@Test func cardDuelSeededStartIsReproducible() {
    let initialA = CardDuelState(seed: 12345)
    let initialB = CardDuelState(seed: 12345)

    let (startedA, _) = cardDuelReducer(initialA, .start)
    let (startedB, _) = cardDuelReducer(initialB, .start)

    #expect(startedA.playerHand == startedB.playerHand)
    #expect(startedA.aiHand == startedB.aiHand)
    #expect(startedA.playerDeck == startedB.playerDeck)
    #expect(startedA.aiDeck == startedB.aiDeck)
}

@Test func cardDuelIgnoresFurtherActionsAfterGameOver() {
    var state = CardDuelState(seed: 1)
    state.isRunning = true
    state.turnOwner = .player
    state.aiHP = 1

    let finisher = testCard(id: 7, attribute: .flame, skill: .strike, baseValue: 2)
    let (finished, _) = cardDuelReducer(state, .resolveCard(owner: .player, card: finisher))

    #expect(finished.isGameOver)
    #expect(!finished.isRunning)

    let (afterDraw, _) = cardDuelReducer(finished, .drawForCurrentTurn)
    let (afterPlay, _) = cardDuelReducer(finished, .playerPlayCard(index: 0))

    #expect(afterDraw == finished)
    #expect(afterPlay == finished)
}

private func testCard(id: Int, attribute: CardAttribute, skill: CardSkill, baseValue: Int) -> DuelCard {
    DuelCard(id: id, attribute: attribute, skill: skill, baseValue: baseValue)
}
