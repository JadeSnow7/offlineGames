/// Central registry of all available games.
/// Games register themselves at app launch; the catalog UI reads from here.
public actor GameRegistry {
    /// All registered game definitions.
    public private(set) var games: [GameDefinition] = []

    public init(games: [GameDefinition] = []) {
        self.games = games
    }

    /// Register a game definition.
    public func register(_ game: GameDefinition) {
        games.append(game)
    }

    /// All registered metadata, sorted by display name.
    public var allMetadata: [GameMetadata] {
        games.map(\.metadata).sorted { $0.displayName < $1.displayName }
    }

    /// All game definitions sorted by display name.
    public func allGames() -> [GameDefinition] {
        games.sorted { $0.metadata.displayName < $1.metadata.displayName }
    }

    /// Look up a game definition by ID.
    public func game(withID id: String) -> GameDefinition? {
        games.first { $0.metadata.id == id }
    }
}
