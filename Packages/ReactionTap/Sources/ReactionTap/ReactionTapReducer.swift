import Foundation
import CoreEngine

/// Pure reducer for reaction tap game logic.
public let reactionTapReducer: Reduce<ReactionTapState, ReactionTapAction> = { state, action in
    var newState = state
    switch action {
    case .start:
        newState.isRunning = true
        newState.phase = .ready
    case .showStimulus:
        newState.phase = .stimulus
        newState.stimulusTime = .now
    case .tap(let tapTime):
        switch newState.phase {
        case .ready:
            newState.phase = .tooEarly
        case .stimulus:
            if let stimulusTime = newState.stimulusTime {
                let reaction = tapTime.timeIntervalSince(stimulusTime)
                newState.reactionTimes.append(reaction)
                newState.phase = .result(reactionTime: reaction)
            }
        default:
            break
        }
    case .nextRound:
        if newState.currentRound >= newState.totalRounds {
            newState.phase = .finished
            newState.isGameOver = true
            let avg = newState.reactionTimes.reduce(0, +) / Double(newState.reactionTimes.count)
            newState.score = max(0, Int((1.0 - avg) * 1000))
        } else {
            newState.currentRound += 1
            newState.phase = .ready
            newState.stimulusTime = nil
        }
    case .reset:
        newState = ReactionTapState(totalRounds: state.totalRounds)
    }
    return (newState, .none)
}
