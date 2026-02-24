import Foundation
import CoreEngine

/// Pure reducer for reaction tap game logic.
public let reactionTapReducer: Reduce<ReactionTapState, ReactionTapAction> = { state, action in
    var newState = state

    switch action {
    case .start:
        newState = ReactionTapState(totalRounds: state.totalRounds)
        newState.isRunning = true
        newState.phase = .ready

    case .pause:
        newState.isRunning = false

    case .resume:
        guard !newState.isGameOver else { break }
        newState.isRunning = true
        if newState.phase == .waiting {
            newState.phase = .ready
        }

    case .showStimulus:
        guard newState.isRunning else { break }
        guard newState.phase == .ready else { break }
        newState.phase = .stimulus
        newState.stimulusTime = .now

    case .tap(let tapTime):
        guard newState.isRunning else { break }

        switch newState.phase {
        case .ready:
            // Early tap: apply penalty and move to round result.
            let penalty = 1.5
            newState.reactionTimes.append(penalty)
            newState.phase = .tooEarly
            newState.stimulusTime = nil

        case .stimulus:
            guard let stimulusTime = newState.stimulusTime else { break }
            let reaction = max(0, tapTime.timeIntervalSince(stimulusTime))
            newState.reactionTimes.append(reaction)
            newState.phase = .result(reactionTime: reaction)
            newState.stimulusTime = nil

        case .tooEarly, .result, .finished, .waiting:
            break
        }

    case .nextRound:
        guard newState.phase != .waiting else { break }

        if newState.currentRound >= newState.totalRounds {
            newState.phase = .finished
            newState.isGameOver = true
            newState.isRunning = false
            newState.score = computedScore(from: newState.reactionTimes)
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

private func computedScore(from reactionTimes: [Double]) -> Int {
    guard !reactionTimes.isEmpty else { return 0 }
    let average = reactionTimes.reduce(0, +) / Double(reactionTimes.count)
    let score = 1200 - Int(average * 1000)
    return max(0, score)
}
