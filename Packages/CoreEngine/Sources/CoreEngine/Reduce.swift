/// A pure function that takes the current state and an action,
/// and returns a new state plus any effects to execute.
///
/// This is the core building block of the TCA-style architecture.
/// Every game implements its logic as a `Reduce` function.
///
/// ```swift
/// let snakeReducer: Reduce<SnakeState, SnakeAction> = { state, action in
///     switch action {
///     case .tick:
///         var newState = state
///         newState.moveSnake()
///         return (newState, .none)
///     }
/// }
/// ```
public typealias Reduce<State: Sendable, Action: Sendable> =
    @Sendable (State, Action) -> (State, Effect<Action>)
