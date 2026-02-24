import SwiftUI
import GameUI
import GameCatalog
import SnakeGame
import BlockPuzzle
import BreakoutGame
import CardDuel
import MinesweeperGame
import MemoryMatch
import ReactionTap

/// Thin shell App target — all logic lives in packages.
@main
struct OfflineGamesApp: App {
    @AppStorage("settings.languagePreference")
    private var languagePreference: String = AppLanguage.system.rawValue

    private let registry = GameRegistry(
        games: [
            SnakeDefinition(),
            BlockPuzzleDefinition(),
            BreakoutDefinition(),
            CardDuelDefinition(),
            MinesweeperDefinition(),
            MemoryMatchDefinition(),
            ReactionTapDefinition()
        ]
    )

    var body: some Scene {
        WindowGroup {
            AppRouter(registry: registry)
                .environment(\.locale, selectedLanguage.resolvedLocale)
        }
    }

    private var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: languagePreference) ?? .system
    }
}
