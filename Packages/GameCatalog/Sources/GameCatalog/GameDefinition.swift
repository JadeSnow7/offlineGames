import SwiftUI

/// Protocol that each game module implements to register itself
/// with the catalog. Provides the view factory and metadata.
public protocol GameDefinition: Sendable {
    /// Metadata for display in the catalog.
    var metadata: GameMetadata { get }

    /// Create the root view for this game.
    @MainActor
    func makeRootView() -> AnyView
}
