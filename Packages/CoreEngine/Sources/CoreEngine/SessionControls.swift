/// Standardized session lifecycle actions every game reducer should expose.
public struct SessionControlActions<Action: Sendable>: Sendable {
    public let start: Action
    public let pause: Action
    public let resume: Action
    public let reset: Action

    public init(start: Action, pause: Action, resume: Action, reset: Action) {
        self.start = start
        self.pause = pause
        self.resume = resume
        self.reset = reset
    }
}

/// Tick configuration for reducers that rely on a time-driven loop.
public struct TickConfiguration<Action: Sendable>: Sendable {
    public let tickRate: Double
    public let makeAction: @Sendable (Double) -> Action

    public init(tickRate: Double, makeAction: @escaping @Sendable (Double) -> Action) {
        self.tickRate = tickRate
        self.makeAction = makeAction
    }
}
