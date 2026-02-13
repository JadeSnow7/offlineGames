/// Actor-based state store that holds game state and dispatches actions
/// through a reducer. This is the single source of truth for game state.
///
/// All state mutations go through `send(_:)`, which applies the reducer
/// and executes any returned effects.
public actor StateStore<State: GameState, Action: Sendable> {
    /// Current state snapshot.
    public private(set) var state: State

    /// The reducer function applied on every action.
    private let reducer: Reduce<State, Action>

    /// Subscribers notified on state changes.
    private var listeners: [@Sendable (State) -> Void] = []

    /// Creates a store with an initial state and a reducer.
    public init(initialState: State, reducer: @escaping Reduce<State, Action>) {
        self.state = initialState
        self.reducer = reducer
    }

    /// Dispatch an action through the reducer. Returns the new state.
    @discardableResult
    public func send(_ action: Action) async -> State {
        let (newState, effect) = reducer(state, action)
        state = newState
        for listener in listeners { listener(newState) }
        await executeEffect(effect)
        return state
    }

    /// Subscribe to state changes.
    public func subscribe(_ listener: @escaping @Sendable (State) -> Void) {
        listeners.append(listener)
    }

    // MARK: - Private

    private func executeEffect(_ effect: Effect<Action>) async {
        switch effect {
        case .none:
            break
        case .run(let work):
            if let action = try? await work() {
                await send(action)
            }
        case .fireAndForget(let work):
            try? await work()
        case .batch(let effects):
            for e in effects {
                await executeEffect(e)
            }
        }
    }
}
