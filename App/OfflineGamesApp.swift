import SwiftUI
import GameUI
import GameCatalog

/// Thin shell App target — all logic lives in packages.
@main
struct OfflineGamesApp: App {
    var body: some Scene {
        WindowGroup {
            AppRouter()
        }
    }
}
