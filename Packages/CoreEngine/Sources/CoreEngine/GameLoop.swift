import Foundation

/// Actor-based game loop that drives tick updates at a fixed interval.
/// Decoupled from rendering — only drives state updates.
public actor GameLoop {
    /// Desired ticks per second.
    public let tickRate: Double

    /// Whether the loop is currently running.
    public private(set) var isRunning: Bool = false

    /// Callback invoked on each tick with the delta time in seconds.
    private let onTick: @Sendable (Double) async -> Void

    private var task: Task<Void, Never>?

    /// Creates a game loop with the given tick rate and tick handler.
    public init(tickRate: Double = 60.0,
                onTick: @escaping @Sendable (Double) async -> Void) {
        self.tickRate = tickRate
        self.onTick = onTick
    }

    /// Start the game loop.
    public func start() {
        guard !isRunning else { return }
        isRunning = true
        let interval = 1.0 / tickRate
        let tick = onTick
        task = Task { [interval, tick] in
            var lastTime = CFAbsoluteTimeGetCurrent()
            while !Task.isCancelled {
                let now = CFAbsoluteTimeGetCurrent()
                let delta = now - lastTime
                lastTime = now
                await tick(delta)
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }

    /// Stop the game loop.
    public func stop() {
        isRunning = false
        task?.cancel()
        task = nil
    }
}
