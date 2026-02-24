import Foundation

/// Naming conventions for high score persistence keys.
public enum HighScoreKey {
    /// Standard key namespace for per-session scores by game.
    public static func session(gameID: String) -> String {
        "session.\(gameID)"
    }
}

/// Actor that manages persistent high scores using UserDefaults.
public actor HighScoreStore {
    private let defaults: UserDefaults
    private let storageKey: String

    /// Creates a store scoped to a specific game.
    public init(gameID: String, defaults: UserDefaults = .standard) {
        self.storageKey = "highscores.\(gameID)"
        self.defaults = defaults
    }

    /// Returns the top scores, sorted descending, up to `limit`.
    public func topScores(limit: Int = 10) -> [ScoreEntry] {
        guard let data = defaults.data(forKey: storageKey),
              let entries = try? JSONDecoder().decode([ScoreEntry].self, from: data)
        else { return [] }
        return Array(entries.sorted { $0.score > $1.score }.prefix(limit))
    }

    /// Record a new score. Returns `true` if it's a new high score.
    @discardableResult
    public func record(score: Int, playerName: String = "Player") -> Bool {
        var entries = topScores(limit: .max)
        let isHigh = entries.isEmpty || score > (entries.first?.score ?? 0)
        entries.append(ScoreEntry(score: score, playerName: playerName, date: .now))
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: storageKey)
        }
        return isHigh
    }
}

/// A single score entry.
public struct ScoreEntry: Codable, Sendable, Equatable {
    public let score: Int
    public let playerName: String
    public let date: Date

    public init(score: Int, playerName: String, date: Date) {
        self.score = score
        self.playerName = playerName
        self.date = date
    }
}
