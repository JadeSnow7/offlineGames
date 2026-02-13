/// Represents an effect to be executed by the runtime.
/// Effects are the only way to perform side-effects in the architecture.
/// Reducers return effects alongside state transitions.
public enum Effect<Action: Sendable>: Sendable {
    /// No effect — reducer returned a pure state transition.
    case none

    /// Run an async closure that may produce an action to feed back.
    case run(@Sendable () async throws -> Action?)

    /// Fire-and-forget async work with no feedback action.
    case fireAndForget(@Sendable () async throws -> Void)

    /// Combine multiple effects.
    case batch([Effect<Action>])
}
