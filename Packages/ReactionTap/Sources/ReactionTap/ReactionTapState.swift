import Foundation
import CoreEngine

/// State of a reaction speed test game session.
public struct ReactionTapState: GameState, Equatable, Sendable {
    /// Current round (1-based).
    public var currentRound: Int

    /// Total rounds per session.
    public let totalRounds: Int

    /// Reaction times recorded (in seconds).
    public var reactionTimes: [Double]

    /// Timestamp when the stimulus appeared.
    public var stimulusTime: Date?

    /// Current phase of the game.
    public var phase: Phase

    /// Current score (lower average = higher score).
    public var score: Int

    /// Whether the game is running.
    public var isRunning: Bool

    /// Whether all rounds are complete.
    public var isGameOver: Bool

    public init(totalRounds: Int = 5) {
        self.currentRound = 1
        self.totalRounds = totalRounds
        self.reactionTimes = []
        self.stimulusTime = nil
        self.phase = .waiting
        self.score = 0
        self.isRunning = false
        self.isGameOver = false
    }

    /// Game phases.
    public enum Phase: Sendable, Equatable {
        case waiting
        case ready
        case stimulus
        case tooEarly
        case result(reactionTime: Double)
        case finished
    }
}
