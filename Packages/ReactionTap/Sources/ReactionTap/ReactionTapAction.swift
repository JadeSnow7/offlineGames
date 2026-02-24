import Foundation

/// Actions for the reaction tap game.
public enum ReactionTapAction: Sendable {
    case start
    case pause
    case resume
    case showStimulus
    case tap(at: Date)
    case nextRound
    case reset
}
