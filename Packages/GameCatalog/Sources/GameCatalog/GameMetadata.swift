import SwiftUI

/// Metadata describing a game in the catalog.
public struct GameMetadata: Sendable, Identifiable, Equatable {
    /// Unique identifier for the game.
    public let id: String

    /// Display name shown in the catalog.
    public let displayName: String

    /// Short description of the game.
    public let description: String

    /// SF Symbol name for the game icon.
    public let iconName: String

    /// Accent color for the game's UI.
    public let accentColor: Color

    /// Minimum recommended age.
    public let minAge: Int

    /// Game category.
    public let category: GameCategory

    public init(id: String, displayName: String, description: String,
                iconName: String, accentColor: Color,
                minAge: Int = 4, category: GameCategory) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.iconName = iconName
        self.accentColor = accentColor
        self.minAge = minAge
        self.category = category
    }
}

/// Categories of games.
public enum GameCategory: String, Sendable, CaseIterable {
    case action = "Action"
    case puzzle = "Puzzle"
    case classic = "Classic"
    case reflex = "Reflex"
}
