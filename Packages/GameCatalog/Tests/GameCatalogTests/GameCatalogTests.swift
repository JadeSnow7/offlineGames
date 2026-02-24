import SwiftUI
import Testing
@testable import GameCatalog

@Test func gameCatalogModuleLoads() async throws {
    // Verify module imports successfully
}

@Test func gameRegistrySortsGamesByDisplayName() async {
    let registry = GameRegistry(games: [
        TestGameDefinition(id: "b", displayName: "B"),
        TestGameDefinition(id: "a", displayName: "A")
    ])

    let allGames = await registry.allGames()

    #expect(allGames.map { $0.metadata.id } == ["a", "b"])
}

private struct TestGameDefinition: GameDefinition {
    let id: String
    let displayName: String

    var metadata: GameMetadata {
        GameMetadata(
            id: id,
            displayName: displayName,
            description: "desc",
            iconName: "star",
            accentColor: .blue,
            category: .classic
        )
    }

    @MainActor
    func makeRootView() -> AnyView {
        AnyView(EmptyView())
    }
}
