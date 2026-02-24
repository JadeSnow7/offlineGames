import Foundation
import Testing
@testable import ReactionTap

@Test func reactionTapEarlyTapPenalized() {
    let initial = ReactionTapState(totalRounds: 3)
    let (started, _) = reactionTapReducer(initial, .start)
    let (tapped, _) = reactionTapReducer(started, .tap(at: .now))

    #expect(tapped.phase == .tooEarly)
    #expect(tapped.reactionTimes.count == 1)
    #expect(tapped.reactionTimes[0] == 1.5)
}

@Test func reactionTapRecordsStimulusReaction() {
    let initial = ReactionTapState(totalRounds: 3)
    let (started, _) = reactionTapReducer(initial, .start)
    let (stimulus, _) = reactionTapReducer(started, .showStimulus)

    let tapTime = Date().addingTimeInterval(0.3)
    let (result, _) = reactionTapReducer(stimulus, .tap(at: tapTime))

    if case let .result(reaction) = result.phase {
        #expect(reaction >= 0)
    } else {
        Issue.record("Expected result phase")
    }
    #expect(result.reactionTimes.count == 1)
}

@Test func reactionTapFinishesAfterLastRound() {
    var state = ReactionTapState(totalRounds: 1)
    state.isRunning = true
    state.phase = .result(reactionTime: 0.4)
    state.reactionTimes = [0.4]

    let (finished, _) = reactionTapReducer(state, .nextRound)

    #expect(finished.isGameOver)
    #expect(!finished.isRunning)
    #expect(finished.phase == .finished)
    #expect(finished.score > 0)
}
