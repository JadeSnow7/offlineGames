[English](Architecture.md) | [简体中文](Architecture.zh-Hans.md)

# Architecture

## Table of Contents

1. [Overview](#overview)
2. [Design Principles](#design-principles)
3. [Module Dependency Graph](#module-dependency-graph)
4. [Unidirectional Data Flow](#unidirectional-data-flow)
5. [StateStore Actor Pattern](#statestore-actor-pattern)
6. [Reduce Function](#reduce-function)
7. [Effect System](#effect-system)
8. [Render Pipeline](#render-pipeline)
9. [RenderCommand Enum](#rendercommand-enum)
10. [GameLoop Actor](#gameloop-actor)
11. [Input Handling](#input-handling)
12. [Audio and Haptic Actors](#audio-and-haptic-actors)
13. [C++ Interop Layer](#c-interop-layer)
14. [Data Flow Diagrams](#data-flow-diagrams)

---

## Overview

offlineGames uses a **TCA-style (The Composable Architecture) unidirectional architecture** adapted specifically for real-time game development. The architecture enforces a single direction of data flow: user input and system events produce Actions, Actions are fed into a pure Reduce function that returns new State and Effects, State changes drive rendering, and Effects produce asynchronous work that may feed further Actions back into the loop.

This approach provides several advantages for game development:

- **Deterministic state transitions** -- every state change is the result of a known Action, making debugging and replay trivial.
- **Testability** -- Reduce functions are pure, requiring no mocks or stubs. Feed in State and Action, assert on the output State and Effects.
- **Concurrency safety** -- all shared mutable state lives inside Swift actors, eliminating data races under Swift 6 strict concurrency.
- **Rendering decoupled from logic** -- game logic never touches Metal or SpriteKit directly. It emits RenderCommands that the render pipeline interprets.
- **Composability** -- each game is a self-contained Swift package that plugs into the shared CoreEngine and App shell.

---

## Design Principles

| Principle | Description |
|---|---|
| Unidirectional flow | State flows down, actions flow up. No bidirectional bindings. |
| Pure core, effectful shell | All game logic is pure. Side effects are declared, not executed, by the reducer. |
| Actor isolation | Every piece of shared mutable state is an actor. No classes, no locks. |
| Protocol-driven rendering | Rendering is abstracted behind protocols so Metal and SpriteKit can be swapped. |
| Zero third-party deps | The entire project depends only on Apple frameworks and our own C++ core. |
| Minimal modules | Each file has one responsibility. Each package has one purpose. |

---

## Module Dependency Graph

The project is organized as a layered dependency graph. Dependencies flow strictly downward -- no circular dependencies are permitted.

```
+----------------------------------------------------------+
|                       App Shell                          |
|  (offlineGamesApp, NavigationCoordinator, GamePicker)    |
+---------------------------+------------------------------+
                            |
            +---------------+----------------+
            |               |                |
   +--------v------+ +-----v-------+ +------v--------+
   | SnakePackage  | | TetrisPackage| | MinesweeperPkg|   <-- Game Packages
   | (State,Action | | (State,Action| | (State,Action |
   |  Reducer,View)| |  Reducer,View| |  Reducer,View)|
   +--------+------+ +-----+-------+ +------+--------+
            |               |                |
            +---------------+----------------+
                            |
              +-------------v--------------+
              |         CoreEngine         |
              | (StateStore, Effect,       |
              |  GameLoop, RenderPipeline, |
              |  InputEvent, AudioActor,   |
              |  HapticActor, Protocols)   |
              +-------------+--------------+
                            |
              +-------------v--------------+
              |       CppCoreSwift         |
              | (Swift overlay / bridging) |
              +-------------+--------------+
                            |
              +-------------v--------------+
              |          CppCore           |
              | (C++ math, collision,      |
              |  noise, grid algorithms)   |
              +----------------------------+
```

### Package Descriptions

- **CppCore** -- Pure C++ library containing performance-critical algorithms: vector math, AABB and circle collision detection, Perlin noise, grid-based pathfinding, and random number generation. No Apple framework dependencies.
- **CppCoreSwift** -- Thin Swift overlay that imports CppCore via C++ interop and provides ergonomic Swift APIs. Converts between C++ value types and Swift value types.
- **CoreEngine** -- The heart of the architecture. Contains the StateStore actor, Effect type, GameLoop actor, RenderPipeline protocol, RenderCommand enum, InputEvent enum, AudioActor, HapticActor, and all shared protocols. Every game package depends on CoreEngine.
- **Game Packages** (SnakePackage, TetrisPackage, MinesweeperPackage, etc.) -- Each game is a standalone Swift package that defines its own State, Action, Reducer, logic helpers, and SwiftUI views. Game packages depend on CoreEngine and optionally on CppCoreSwift.
- **App Shell** -- The main application target. Contains the app entry point, navigation coordinator, game picker UI, and wires each game package into the running app. The App shell depends on all game packages and CoreEngine.

---

## Unidirectional Data Flow

The core data flow cycle is:

```
User taps button
       |
       v
Action.userTapped(.start)
       |
       v
StateStore.send(action)
       |
       v
reduce(state, action) -> (newState, effect)
       |                        |
       v                        v
State published          Effect executed
       |                        |
       v                        |
SwiftUI re-renders              |
RenderCommands emitted          |
       |                        |
       v                        v
RenderPipeline draws    Async result becomes new Action
                                |
                                v
                        StateStore.send(newAction)
                                |
                                v
                           (cycle repeats)
```

There is exactly one StateStore per game session. All mutations to game state pass through the reduce function. Views observe the store's published state and re-render. Effects are the only mechanism for performing side effects (timers, audio, haptics, persistence).

---

## StateStore Actor Pattern

The `StateStore` is a Swift `actor` that owns the single source of truth for a game's state. Being an actor guarantees that all state mutations are serialized, eliminating data races even when actions arrive from multiple concurrent contexts (UI thread, game loop, network callbacks).

```swift
/// The central state container for a single game session.
/// All state mutations are serialized through this actor.
public actor StateStore<State: Sendable, Action: Sendable> {

    // MARK: - Properties

    /// The current state. Published to observers after each reduction.
    public private(set) var state: State

    /// The reduce function that defines state transitions.
    private let reduce: (State, Action) -> (State, Effect<Action>)

    /// Stream continuation for broadcasting state changes.
    private var continuations: [UUID: AsyncStream<State>.Continuation] = [:]

    // MARK: - Initialization

    public init(
        initialState: State,
        reduce: @escaping @Sendable (State, Action) -> (State, Effect<Action>)
    ) {
        self.state = initialState
        self.reduce = reduce
    }

    // MARK: - Sending Actions

    /// Process an action through the reduce function, update state,
    /// notify observers, and execute any returned effects.
    public func send(_ action: Action) {
        let (newState, effect) = reduce(state, action)
        state = newState

        // Broadcast new state to all observers.
        for (_, continuation) in continuations {
            continuation.yield(newState)
        }

        // Execute the effect, feeding resulting actions back into send.
        Task { [weak self] in
            await self?.execute(effect)
        }
    }

    // MARK: - Observation

    /// Returns an AsyncStream that yields the current state followed by
    /// all subsequent state changes.
    public func observe() -> AsyncStream<State> {
        let id = UUID()
        return AsyncStream { continuation in
            continuation.yield(state)
            continuations[id] = continuation
            continuation.onTermination = { _ in
                Task { [weak self] in
                    await self?.removeContinuation(id: id)
                }
            }
        }
    }

    // MARK: - Private

    private func removeContinuation(id: UUID) {
        continuations.removeValue(forKey: id)
    }

    private func execute(_ effect: Effect<Action>) async {
        switch effect {
        case .none:
            break

        case .run(let operation):
            if let action = await operation() {
                await send(action)
            }

        case .fireAndForget(let work):
            await work()

        case .batch(let effects):
            await withTaskGroup(of: Void.self) { group in
                for e in effects {
                    group.addTask { [weak self] in
                        await self?.execute(e)
                    }
                }
            }
        }
    }
}
```

### Key Design Decisions

- **Actor, not class** -- Using an actor instead of a class with locks guarantees data-race freedom under Swift 6 strict concurrency. The compiler enforces isolation.
- **Generic over State and Action** -- The same StateStore powers every game. Snake, Tetris, and Minesweeper each define their own State and Action types and plug them in.
- **AsyncStream for observation** -- SwiftUI views and other consumers observe state changes via AsyncStream, which integrates naturally with structured concurrency and `.task` view modifiers.
- **Weak self in effect execution** -- Effects capture `[weak self]` to avoid retain cycles when a game session is torn down while effects are in flight.

---

## Reduce Function

The reduce function is the single point where state transitions occur. Its signature is:

```swift
(State, Action) -> (State, Effect<Action>)
```

### Characteristics

- **Pure** -- Given the same State and Action, the reduce function always returns the same output State and Effect. No side effects, no global state access, no I/O.
- **Synchronous** -- The reduce function runs synchronously on the actor's executor. It must not perform blocking or long-running work. Expensive computation belongs in an Effect.
- **Total** -- The reduce function handles every possible Action. There is no default/fallback case that silently drops actions. Every action is explicitly matched.
- **Returns both state and effect** -- Rather than mutating state in place and imperatively kicking off side effects, the reduce function declares what the new state is and what side effects should occur. The StateStore is responsible for applying the state and executing the effects.

### Example: Snake Reducer

```swift
public func snakeReducer(
    state: SnakeState,
    action: SnakeAction
) -> (SnakeState, Effect<SnakeAction>) {
    var state = state

    switch action {
    case .startGame:
        state.phase = .playing
        state.snake = Snake.initial(gridSize: state.gridSize)
        state.food = FoodSpawner.spawn(avoiding: state.snake.segments, gridSize: state.gridSize)
        state.score = 0
        return (state, .run {
            try? await Task.sleep(for: .milliseconds(100))
            return .tick
        })

    case .tick:
        guard state.phase == .playing else {
            return (state, .none)
        }
        let moveResult = SnakeLogic.advance(snake: state.snake, direction: state.direction, gridSize: state.gridSize)
        switch moveResult {
        case .moved(let newSnake):
            state.snake = newSnake
            if newSnake.head == state.food.position {
                state.score += state.food.points
                state.snake = SnakeLogic.grow(snake: newSnake)
                state.food = FoodSpawner.spawn(avoiding: state.snake.segments, gridSize: state.gridSize)
                return (state, .batch([
                    .fireAndForget { await AudioActor.shared.play(.eat) },
                    .fireAndForget { await HapticActor.shared.trigger(.light) },
                    .run {
                        try? await Task.sleep(for: .milliseconds(state.speed.tickInterval))
                        return .tick
                    }
                ]))
            }
            return (state, .run {
                try? await Task.sleep(for: .milliseconds(state.speed.tickInterval))
                return .tick
            })

        case .collision:
            state.phase = .gameOver
            return (state, .batch([
                .fireAndForget { await AudioActor.shared.play(.gameOver) },
                .fireAndForget { await HapticActor.shared.trigger(.heavy) }
            ]))
        }

    case .changeDirection(let newDirection):
        guard newDirection.isValid(current: state.direction) else {
            return (state, .none)
        }
        state.direction = newDirection
        return (state, .none)

    case .pauseGame:
        state.phase = .paused
        return (state, .none)

    case .resumeGame:
        state.phase = .playing
        return (state, .run {
            try? await Task.sleep(for: .milliseconds(state.speed.tickInterval))
            return .tick
        })

    case .resetGame:
        state = SnakeState.initial(gridSize: state.gridSize)
        return (state, .none)
    }
}
```

### Testing a Reducer

Because reducers are pure functions, testing is trivial:

```swift
func testEatingFoodIncrementsScore() {
    var state = SnakeState.initial(gridSize: GridSize(width: 10, height: 10))
    state.snake = Snake(segments: [Position(x: 5, y: 5)])
    state.food = Food(position: Position(x: 6, y: 5), points: 10)
    state.direction = .right
    state.phase = .playing

    let (newState, _) = snakeReducer(state: state, action: .tick)

    XCTAssertEqual(newState.score, 10)
}
```

No mocks. No dependency injection containers. No setup/teardown ceremony. Feed state and action in, assert on the output.

---

## Effect System

The `Effect` type is an enum that declares side effects without executing them. The StateStore is responsible for interpreting and executing effects after the reduce function returns.

```swift
/// Declares a side effect to be executed by the StateStore.
/// Effects are the ONLY way for game logic to interact with the outside world.
public enum Effect<Action: Sendable>: Sendable {

    /// No side effect. The most common case -- most actions only change state.
    case none

    /// An asynchronous operation that may produce a new Action.
    /// The returned action (if any) is fed back into the StateStore.
    case run(@Sendable () async -> Action?)

    /// An asynchronous operation that does NOT produce an Action.
    /// Used for fire-and-forget work like playing audio or triggering haptics.
    case fireAndForget(@Sendable () async -> Void)

    /// Execute multiple effects concurrently.
    /// All effects in the batch run in parallel via a TaskGroup.
    case batch([Effect<Action>])
}
```

### Effect Variants in Detail

#### `Effect.none`

The identity effect. Used when an action only changes state and requires no side effects. This is the most common return value.

```swift
case .changeDirection(let dir):
    state.direction = dir
    return (state, .none)
```

#### `Effect.run`

An asynchronous operation that may produce a follow-up Action. The closure runs in a detached context. If it returns an Action, that action is sent back to the StateStore, continuing the cycle. If it returns `nil`, the cycle ends.

Common uses:
- Timers (sleep then return `.tick`)
- Loading data from disk (return `.dataLoaded(data)`)
- Network requests (return `.responseReceived(response)`)

```swift
case .startGame:
    state.phase = .playing
    return (state, .run {
        try? await Task.sleep(for: .seconds(1))
        return .tick
    })
```

#### `Effect.fireAndForget`

An asynchronous operation that performs work but does not produce a follow-up Action. The StateStore executes it and discards the result.

Common uses:
- Playing a sound effect
- Triggering haptic feedback
- Logging analytics
- Persisting a high score

```swift
return (state, .fireAndForget {
    await AudioActor.shared.play(.lineClear)
})
```

#### `Effect.batch`

Executes multiple effects concurrently. Each effect in the array runs as a separate child task within a `TaskGroup`. This is used when a single action needs to trigger multiple independent side effects.

```swift
return (state, .batch([
    .fireAndForget { await AudioActor.shared.play(.eat) },
    .fireAndForget { await HapticActor.shared.trigger(.light) },
    .run {
        try? await Task.sleep(for: .milliseconds(tickInterval))
        return .tick
    }
]))
```

### Composition

Effects compose naturally. A helper function can return an Effect, and callers can incorporate it into a batch:

```swift
func playFeedback(sound: SoundEffect, haptic: HapticPattern) -> Effect<SnakeAction> {
    .batch([
        .fireAndForget { await AudioActor.shared.play(sound) },
        .fireAndForget { await HapticActor.shared.trigger(haptic) }
    ])
}

// In the reducer:
return (state, .batch([
    playFeedback(sound: .eat, haptic: .light),
    .run { ... }
]))
```

---

## Render Pipeline

The `RenderPipeline` protocol abstracts the rendering backend. Game logic never imports Metal, SpriteKit, or any rendering framework directly. Instead, it emits `RenderCommand` values, and the pipeline interprets them.

```swift
/// Abstraction over the rendering backend.
/// Implementations exist for Metal (high-performance) and SpriteKit (rapid prototyping).
public protocol RenderPipeline: Sendable {

    /// Prepare resources needed before the first frame.
    func setup(viewportSize: CGSize) async

    /// Render a frame using the provided render commands.
    func render(commands: [RenderCommand]) async

    /// Handle viewport resizing (device rotation, window resize).
    func resize(to size: CGSize) async

    /// Release all GPU resources.
    func teardown() async
}
```

### Metal Implementation

The `MetalRenderPipeline` is the primary renderer for shipped games. It manages a `MTLDevice`, command queue, render pass descriptors, and pipeline state objects. It batches draw calls by texture atlas and uses triple-buffered semaphores for smooth frame pacing.

```swift
public actor MetalRenderPipeline: RenderPipeline {

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState?
    private var vertexBuffer: MTLBuffer?
    private let inflightSemaphore = DispatchSemaphore(value: 3)

    public init(device: MTLDevice) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
    }

    public func setup(viewportSize: CGSize) async {
        // Load shaders, create pipeline state objects,
        // allocate vertex/index buffers, load texture atlases.
    }

    public func render(commands: [RenderCommand]) async {
        // Sort commands by layer, batch by texture,
        // encode draw calls into a command buffer, commit.
    }

    public func resize(to size: CGSize) async {
        // Recreate depth/stencil textures, update projection matrix.
    }

    public func teardown() async {
        // Release all Metal resources.
    }
}
```

### SpriteKit Implementation

The `SpriteKitRenderPipeline` is used for rapid prototyping and games where SpriteKit's built-in physics or particle systems are useful. It translates RenderCommands into SKNode tree mutations.

```swift
public actor SpriteKitRenderPipeline: RenderPipeline {

    private weak var scene: SKScene?

    public init(scene: SKScene) {
        self.scene = scene
    }

    public func render(commands: [RenderCommand]) async {
        guard let scene else { return }
        // Diff commands against current node tree,
        // add/remove/update SKNodes as needed.
    }

    // ...
}
```

### Choosing a Pipeline

The pipeline is injected at game session creation time. The App shell decides which pipeline to use based on the game's requirements:

```swift
let pipeline: any RenderPipeline = if game.requiresMetal {
    MetalRenderPipeline(device: MTLCreateSystemDefaultDevice()!)
} else {
    SpriteKitRenderPipeline(scene: gameScene)
}

let store = StateStore(
    initialState: game.initialState,
    reduce: game.reduce
)

let gameLoop = GameLoop(store: store, pipeline: pipeline)
```

---

## RenderCommand Enum

`RenderCommand` is a value type that describes what to draw without referencing any rendering API. It is the bridge between game logic and the render pipeline.

```swift
/// A declarative description of something to render.
/// Game logic produces these; the RenderPipeline consumes them.
public enum RenderCommand: Sendable, Equatable {

    /// Draw a filled rectangle.
    case fillRect(
        rect: CGRect,
        color: GameColor,
        layer: Int
    )

    /// Draw a sprite from a texture atlas.
    case sprite(
        textureName: String,
        position: CGPoint,
        size: CGSize,
        rotation: Float,
        opacity: Float,
        layer: Int
    )

    /// Draw a text label.
    case text(
        content: String,
        position: CGPoint,
        font: GameFont,
        color: GameColor,
        alignment: TextAlignment,
        layer: Int
    )

    /// Draw a line between two points.
    case line(
        from: CGPoint,
        to: CGPoint,
        width: Float,
        color: GameColor,
        layer: Int
    )

    /// Draw a filled circle.
    case circle(
        center: CGPoint,
        radius: Float,
        color: GameColor,
        layer: Int
    )

    /// Set the background clear color for this frame.
    case clearColor(GameColor)

    /// Apply a camera transform for this frame.
    case camera(
        position: CGPoint,
        zoom: Float,
        rotation: Float
    )
}
```

### Why an Enum?

Using an enum instead of direct API calls provides:

- **Backend independence** -- The same game logic renders on Metal, SpriteKit, or a hypothetical future backend.
- **Testability** -- Assert on the RenderCommands produced by a state, without needing a GPU.
- **Serializability** -- RenderCommands can be recorded for replay or debugging.
- **Diffing** -- The pipeline can diff this frame's commands against last frame's to minimize GPU work.

### Generating RenderCommands from State

Each game provides a `renderCommands(from:)` function that converts its State into an array of RenderCommands:

```swift
func renderCommands(from state: SnakeState) -> [RenderCommand] {
    var commands: [RenderCommand] = [
        .clearColor(.background)
    ]

    // Draw grid
    for x in 0..<state.gridSize.width {
        for y in 0..<state.gridSize.height {
            let rect = gridCellRect(x: x, y: y, cellSize: state.cellSize)
            let color: GameColor = (x + y).isMultiple(of: 2) ? .gridLight : .gridDark
            commands.append(.fillRect(rect: rect, color: color, layer: 0))
        }
    }

    // Draw snake
    for (index, segment) in state.snake.segments.enumerated() {
        let rect = gridCellRect(x: segment.x, y: segment.y, cellSize: state.cellSize)
        let color: GameColor = index == 0 ? .snakeHead : .snakeBody
        commands.append(.fillRect(rect: rect, color: color, layer: 1))
    }

    // Draw food
    let foodRect = gridCellRect(x: state.food.position.x, y: state.food.position.y, cellSize: state.cellSize)
    commands.append(.sprite(
        textureName: "food_apple",
        position: CGPoint(x: foodRect.midX, y: foodRect.midY),
        size: foodRect.size,
        rotation: 0,
        opacity: 1,
        layer: 1
    ))

    // Draw score
    commands.append(.text(
        content: "Score: \(state.score)",
        position: CGPoint(x: 10, y: 20),
        font: .system(size: 18, weight: .bold),
        color: .white,
        alignment: .leading,
        layer: 2
    ))

    return commands
}
```

---

## GameLoop Actor

The `GameLoop` actor provides a **fixed-timestep game tick** independent of the display refresh rate. This ensures deterministic physics and game logic regardless of frame rate fluctuations.

```swift
/// Drives the game at a fixed tick rate, decoupled from the display refresh rate.
public actor GameLoop {

    // MARK: - Configuration

    /// The target number of ticks per second.
    public let tickRate: Int

    /// The fixed time step in seconds for each tick.
    public var tickInterval: Duration {
        .seconds(1.0 / Double(tickRate))
    }

    // MARK: - State

    private var isRunning = false
    private var accumulatedTime: Duration = .zero
    private var lastFrameTime: ContinuousClock.Instant?
    private var tickAction: (@Sendable () async -> Void)?

    // MARK: - Initialization

    public init(tickRate: Int = 60) {
        self.tickRate = tickRate
    }

    // MARK: - Control

    /// Start the game loop. The provided closure is called once per fixed tick.
    public func start(onTick: @escaping @Sendable () async -> Void) {
        guard !isRunning else { return }
        isRunning = true
        tickAction = onTick
        lastFrameTime = ContinuousClock.now

        Task { [weak self] in
            await self?.runLoop()
        }
    }

    /// Stop the game loop.
    public func stop() {
        isRunning = false
        tickAction = nil
        lastFrameTime = nil
        accumulatedTime = .zero
    }

    /// Pause the game loop without resetting accumulated time.
    public func pause() {
        isRunning = false
    }

    /// Resume the game loop from where it was paused.
    public func resume() {
        guard !isRunning, tickAction != nil else { return }
        isRunning = true
        lastFrameTime = ContinuousClock.now

        Task { [weak self] in
            await self?.runLoop()
        }
    }

    // MARK: - Private

    private func runLoop() async {
        while isRunning {
            let now = ContinuousClock.now
            let elapsed = now - (lastFrameTime ?? now)
            lastFrameTime = now
            accumulatedTime += elapsed

            // Process as many fixed ticks as have accumulated.
            // Cap at a maximum to prevent spiral of death.
            var ticksThisFrame = 0
            let maxTicksPerFrame = 5

            while accumulatedTime >= tickInterval && ticksThisFrame < maxTicksPerFrame {
                await tickAction?()
                accumulatedTime -= tickInterval
                ticksThisFrame += 1
            }

            // If we hit the cap, discard remaining accumulated time
            // to prevent the spiral of death.
            if ticksThisFrame >= maxTicksPerFrame {
                accumulatedTime = .zero
            }

            // Sleep briefly to yield the executor.
            try? await Task.sleep(for: .milliseconds(1))
        }
    }
}
```

### Fixed Timestep Explained

The fixed-timestep pattern separates the rate at which game logic updates from the rate at which frames are displayed:

```
Display:  |----16ms----|----16ms----|----16ms----|  (60 FPS)
Logic:    |--10ms--|--10ms--|--10ms--|--10ms--|       (100 ticks/sec)
```

Each display frame, the loop calculates how much real time has elapsed, accumulates it, and processes as many fixed-duration ticks as fit. This means:

- At 60 FPS with a 100-tick rate, most frames process 1-2 ticks.
- At 30 FPS (due to thermal throttling), each frame processes 3-4 ticks.
- The game logic always runs at the same effective speed.

### Spiral of Death Protection

If the device is extremely slow and each tick takes longer than the tick interval, ticks accumulate faster than they can be processed. The `maxTicksPerFrame` cap prevents this by discarding excess accumulated time, preferring a momentary slowdown over a permanent freeze.

---

## Input Handling

All user input is normalized into a single `InputEvent` enum before entering the architecture. This decouples game logic from the specific input mechanism (touch, gamepad, keyboard).

```swift
/// Normalized input event. Game logic only sees these,
/// never raw UITouch, GCController, or UIKey events.
public enum InputEvent: Sendable, Equatable {

    // MARK: - Touch / Pointer

    case touchBegan(position: CGPoint, id: Int)
    case touchMoved(position: CGPoint, id: Int)
    case touchEnded(position: CGPoint, id: Int)
    case touchCancelled(id: Int)

    // MARK: - Directional

    case swipe(direction: Direction)
    case joystick(x: Float, y: Float)  // Normalized -1...1

    // MARK: - Buttons

    case buttonDown(GameButton)
    case buttonUp(GameButton)

    // MARK: - Keyboard (iPad, Mac Catalyst)

    case keyDown(KeyCode)
    case keyUp(KeyCode)

    // MARK: - System

    case appDidEnterBackground
    case appWillEnterForeground
}

/// Cardinal and intercardinal directions.
public enum Direction: Sendable, Equatable {
    case up, down, left, right
    case upLeft, upRight, downLeft, downRight
}

/// Logical game buttons, independent of physical input device.
public enum GameButton: Sendable, Equatable {
    case primary    // A / tap / click
    case secondary  // B / long press / right click
    case pause      // Start / menu button
    case dpadUp, dpadDown, dpadLeft, dpadRight
}
```

### Input Translation

Each input source has a translator that converts raw events into `InputEvent` values:

```swift
/// Translates raw UIKit gesture recognizer events into InputEvent values.
struct TouchInputTranslator {
    func translate(gesture: UIGestureRecognizer, in view: UIView) -> InputEvent? {
        // Recognize swipes, taps, etc. and return the appropriate InputEvent.
    }
}

/// Translates Game Controller events into InputEvent values.
struct GamepadInputTranslator {
    func translate(element: GCControllerElement) -> InputEvent? {
        // Map physical buttons and thumbsticks to InputEvent.
    }
}
```

### From InputEvent to Action

Each game defines a mapping from `InputEvent` to its game-specific `Action` type:

```swift
func mapInput(_ event: InputEvent) -> SnakeAction? {
    switch event {
    case .swipe(.up):    return .changeDirection(.up)
    case .swipe(.down):  return .changeDirection(.down)
    case .swipe(.left):  return .changeDirection(.left)
    case .swipe(.right): return .changeDirection(.right)
    case .keyDown(.arrowUp):    return .changeDirection(.up)
    case .keyDown(.arrowDown):  return .changeDirection(.down)
    case .keyDown(.arrowLeft):  return .changeDirection(.left)
    case .keyDown(.arrowRight): return .changeDirection(.right)
    case .buttonDown(.pause):   return .pauseGame
    case .appDidEnterBackground: return .pauseGame
    default: return nil
    }
}
```

---

## Audio and Haptic Actors

Audio playback and haptic feedback are managed by dedicated actors. These are global singletons (one audio system, one haptic engine per device) but their actor isolation makes concurrent access safe.

### AudioActor

```swift
/// Manages all audio playback for the application.
/// Uses AVAudioEngine for low-latency sound effects
/// and AVAudioPlayer for background music.
public actor AudioActor {

    public static let shared = AudioActor()

    private var engine: AVAudioEngine?
    private var soundBuffers: [SoundEffect: AVAudioPCMBuffer] = [:]
    private var musicPlayer: AVAudioPlayer?
    private var isMuted: Bool = false
    private var volume: Float = 1.0

    // MARK: - Setup

    /// Preload all sound effects into memory for low-latency playback.
    public func preload(effects: [SoundEffect]) async {
        engine = AVAudioEngine()
        for effect in effects {
            if let url = Bundle.main.url(forResource: effect.filename, withExtension: "wav"),
               let file = try? AVAudioFile(forReading: url),
               let buffer = AVAudioPCMBuffer(
                   pcmFormat: file.processingFormat,
                   frameCapacity: AVAudioFrameCount(file.length)
               ) {
                try? file.read(into: buffer)
                soundBuffers[effect] = buffer
            }
        }
    }

    // MARK: - Playback

    /// Play a preloaded sound effect.
    public func play(_ effect: SoundEffect) {
        guard !isMuted, let buffer = soundBuffers[effect], let engine else { return }
        let playerNode = AVAudioPlayerNode()
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: buffer.format)
        playerNode.scheduleBuffer(buffer, completionHandler: {
            engine.detach(playerNode)
        })
        playerNode.volume = volume
        playerNode.play()
    }

    /// Start playing background music in a loop.
    public func playMusic(_ music: MusicTrack) {
        guard let url = Bundle.main.url(forResource: music.filename, withExtension: "m4a") else { return }
        musicPlayer = try? AVAudioPlayer(contentsOf: url)
        musicPlayer?.numberOfLoops = -1
        musicPlayer?.volume = volume * 0.5
        musicPlayer?.play()
    }

    /// Stop all audio playback.
    public func stopAll() {
        engine?.stop()
        musicPlayer?.stop()
    }

    // MARK: - Settings

    public func setMuted(_ muted: Bool) { isMuted = muted }
    public func setVolume(_ newVolume: Float) { volume = newVolume.clamped(to: 0...1) }
}
```

### HapticActor

```swift
/// Manages haptic feedback using CoreHaptics.
/// Falls back gracefully on devices without a haptic engine.
public actor HapticActor {

    public static let shared = HapticActor()

    private var engine: CHHapticEngine?
    private var isSupported: Bool = false
    private var isEnabled: Bool = true

    // MARK: - Setup

    public func setup() async {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            isSupported = false
            return
        }
        isSupported = true
        engine = try? CHHapticEngine()
        try? engine?.start()

        // Restart engine if it stops due to app lifecycle.
        engine?.stoppedHandler = { [weak self] _ in
            Task { await self?.restart() }
        }
    }

    // MARK: - Trigger

    /// Trigger a predefined haptic pattern.
    public func trigger(_ pattern: HapticPattern) {
        guard isSupported, isEnabled, let engine else { return }
        let events = pattern.hapticEvents
        guard let hapticPattern = try? CHHapticPattern(events: events, parameters: []),
              let player = try? engine.makePlayer(with: hapticPattern) else { return }
        try? player.start(atTime: CHHapticTimeImmediate)
    }

    // MARK: - Settings

    public func setEnabled(_ enabled: Bool) { isEnabled = enabled }

    // MARK: - Private

    private func restart() {
        try? engine?.start()
    }
}

/// Predefined haptic feedback patterns.
public enum HapticPattern: Sendable {
    case light      // Subtle tap (piece placed)
    case medium     // Moderate tap (line cleared)
    case heavy      // Strong tap (game over)
    case success    // Rising pattern (high score)
    case warning    // Descending pattern (danger)
    case selection  // Tiny tick (menu navigation)

    var hapticEvents: [CHHapticEvent] {
        switch self {
        case .light:
            return [CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0
            )]
        case .heavy:
            return [CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ],
                relativeTime: 0
            )]
        // ... other patterns
        default:
            return []
        }
    }
}
```

---

## C++ Interop Layer

Performance-critical algorithms are implemented in C++ and bridged to Swift via Swift's native C++ interoperability. The interop layer is split into two packages:

### CppCore (Pure C++)

CppCore is a header-only (or compiled) C++ library with no Apple framework dependencies. It can be unit-tested with any C++ test framework. All code lives in the `cppcore` namespace.

```cpp
// CppCore/include/cppcore/vec2.hpp

#pragma once
#include <cmath>

namespace cppcore {

struct Vec2 {
    float x;
    float y;

    Vec2 operator+(const Vec2& other) const { return {x + other.x, y + other.y}; }
    Vec2 operator-(const Vec2& other) const { return {x - other.x, y - other.y}; }
    Vec2 operator*(float scalar) const { return {x * scalar, y * scalar}; }

    float length() const { return std::sqrt(x * x + y * y); }
    float length_squared() const { return x * x + y * y; }
    float dot(const Vec2& other) const { return x * other.x + y * other.y; }

    Vec2 normalized() const {
        float len = length();
        if (len < 1e-7f) return {0, 0};
        return {x / len, y / len};
    }

    static float distance(const Vec2& a, const Vec2& b) {
        return (a - b).length();
    }
};

} // namespace cppcore
```

```cpp
// CppCore/include/cppcore/collision.hpp

#pragma once
#include "vec2.hpp"

namespace cppcore {

struct AABB {
    Vec2 min;
    Vec2 max;

    bool contains(const Vec2& point) const {
        return point.x >= min.x && point.x <= max.x
            && point.y >= min.y && point.y <= max.y;
    }

    bool intersects(const AABB& other) const {
        return min.x <= other.max.x && max.x >= other.min.x
            && min.y <= other.max.y && max.y >= other.min.y;
    }
};

struct Circle {
    Vec2 center;
    float radius;

    bool contains(const Vec2& point) const {
        return Vec2::distance(center, point) <= radius;
    }

    bool intersects(const Circle& other) const {
        float dist = Vec2::distance(center, other.center);
        return dist <= (radius + other.radius);
    }
};

inline bool aabb_circle_intersect(const AABB& box, const Circle& circle) {
    float closest_x = std::max(box.min.x, std::min(circle.center.x, box.max.x));
    float closest_y = std::max(box.min.y, std::min(circle.center.y, box.max.y));
    Vec2 closest{closest_x, closest_y};
    return Vec2::distance(circle.center, closest) <= circle.radius;
}

} // namespace cppcore
```

```cpp
// CppCore/include/cppcore/grid.hpp

#pragma once
#include <vector>
#include <queue>
#include <optional>
#include "vec2.hpp"

namespace cppcore {

struct GridPos {
    int x;
    int y;

    bool operator==(const GridPos& other) const { return x == other.x && y == other.y; }
};

/// Breadth-first search on a 2D grid. Returns the shortest path
/// from start to goal, or an empty vector if no path exists.
inline std::vector<GridPos> bfs_path(
    int width,
    int height,
    const GridPos& start,
    const GridPos& goal,
    const std::vector<bool>& blocked
) {
    if (start == goal) return {start};

    std::vector<int> parent(width * height, -1);
    std::vector<bool> visited(width * height, false);
    std::queue<GridPos> frontier;

    auto index = [width](const GridPos& p) { return p.y * width + p.x; };
    auto in_bounds = [width, height](const GridPos& p) {
        return p.x >= 0 && p.x < width && p.y >= 0 && p.y < height;
    };

    visited[index(start)] = true;
    frontier.push(start);

    const GridPos dirs[] = {{0,1},{0,-1},{1,0},{-1,0}};

    while (!frontier.empty()) {
        auto current = frontier.front();
        frontier.pop();

        for (auto& d : dirs) {
            GridPos next{current.x + d.x, current.y + d.y};
            if (!in_bounds(next)) continue;
            int ni = index(next);
            if (visited[ni] || blocked[ni]) continue;
            visited[ni] = true;
            parent[ni] = index(current);
            if (next == goal) {
                // Reconstruct path.
                std::vector<GridPos> path;
                GridPos p = goal;
                while (!(p == start)) {
                    path.push_back(p);
                    int pi = parent[index(p)];
                    p = {pi % width, pi / width};
                }
                path.push_back(start);
                std::reverse(path.begin(), path.end());
                return path;
            }
            frontier.push(next);
        }
    }
    return {}; // No path found.
}

} // namespace cppcore
```

### CppCoreSwift (Swift Overlay)

CppCoreSwift imports the C++ types and provides Swift-friendly wrappers:

```swift
// CppCoreSwift/Sources/Vector2.swift

import CppCore

/// Swift wrapper around cppcore::Vec2.
public struct Vector2: Sendable, Equatable {
    public var x: Float
    public var y: Float

    public init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }

    public var length: Float {
        var v = cppcore.Vec2(x: x, y: y)
        return v.length()
    }

    public var normalized: Vector2 {
        var v = cppcore.Vec2(x: x, y: y)
        let n = v.normalized()
        return Vector2(x: n.x, y: n.y)
    }

    public func dot(_ other: Vector2) -> Float {
        var v = cppcore.Vec2(x: x, y: y)
        var o = cppcore.Vec2(x: other.x, y: other.y)
        return v.dot(o)
    }

    public static func distance(_ a: Vector2, _ b: Vector2) -> Float {
        let av = cppcore.Vec2(x: a.x, y: a.y)
        let bv = cppcore.Vec2(x: b.x, y: b.y)
        return cppcore.Vec2.distance(av, bv)
    }

    public static func + (lhs: Vector2, rhs: Vector2) -> Vector2 {
        Vector2(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    public static func - (lhs: Vector2, rhs: Vector2) -> Vector2 {
        Vector2(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    public static func * (lhs: Vector2, rhs: Float) -> Vector2 {
        Vector2(x: lhs.x * rhs, y: lhs.y * rhs)
    }
}
```

### When to Use C++

Use C++ (via CppCore) when:

- The algorithm processes large arrays in a tight loop (collision checks across hundreds of entities).
- The algorithm benefits from contiguous memory layout (grid operations).
- The algorithm is a well-known numerical method with established C++ implementations.
- Profiling has identified the Swift implementation as a bottleneck.

Do NOT use C++ when:

- The code is glue logic, UI, or state management.
- The performance difference is negligible (fewer than 1000 iterations).
- The algorithm is simple enough that Swift's optimizer handles it well.

---

## Data Flow Diagrams

### Complete System Data Flow

```
+---------------------+
|     User Input      |  Touch, gamepad, keyboard
+----------+----------+
           |
           v
+----------+----------+
| InputEvent Translator|  Raw events -> InputEvent enum
+----------+----------+
           |
           v
+----------+----------+
|    Input Mapper      |  InputEvent -> Game-specific Action
+----------+----------+
           |
           v
+----------+----------+
|     StateStore       |  Actor: serializes all state mutations
|  +----------------+  |
|  | reduce(s, a)   |  |  Pure function: (State, Action) -> (State, Effect)
|  |  -> (s', eff)  |  |
|  +-------+--------+  |
|          |            |
|  +-------v--------+  |
|  |  Apply State    |  |  state = newState
|  +-------+--------+  |
|          |            |
|  +-------v--------+  |
|  |Execute Effect   |  |  Async: timers, audio, haptics, persistence
|  +-------+--------+  |
+----------+----------+
           |
     +-----+------+
     |            |
     v            v
+----+-----+ +---+----+
| Observers| |Effects  |
| (SwiftUI,| |(Audio,  |
|  render) | | Haptic, |
+----+-----+ | Timer)  |
     |        +---+----+
     v            |
+----+---------+  |  Actions fed back
| renderCmds() |  +-----> StateStore.send(action)
+----+---------+
     |
     v
+----+-----------+
| RenderPipeline |  Metal or SpriteKit
+----------------+
     |
     v
  [Screen]
```

### Game Session Lifecycle

```
App Launch
    |
    v
GamePicker (SwiftUI)
    |
    | User selects a game
    v
NavigationCoordinator
    |
    | Creates game session
    v
+-- Game Session Creation --+
|                           |
|  1. Create initial State  |
|  2. Create StateStore     |
|     with reduce function  |
|  3. Create RenderPipeline |
|     (Metal or SpriteKit)  |
|  4. Create GameLoop       |
|  5. Preload audio         |
|  6. Setup haptics         |
|                           |
+-------------+-------------+
              |
              v
         Game Running
      (tick loop active)
              |
    +---------+---------+
    |         |         |
    v         v         v
  Pause    Game Over   Quit
    |         |         |
    v         v         |
  Resume   Restart      |
    |         |         |
    v         v         |
  (back to  (back to   |
   running)  running)   |
              |         |
              v         v
         Session Teardown
              |
              v
        1. Stop GameLoop
        2. Stop audio
        3. Teardown pipeline
        4. Release StateStore
              |
              v
         GamePicker
```

### State Observation Flow (SwiftUI Integration)

```
StateStore (actor)
    |
    | AsyncStream<State>
    v
GameViewModel (@Observable)
    |
    | @Published properties derived from State
    v
GameView (SwiftUI)
    |
    | body recomputed on state change
    v
Canvas / Metal view
    |
    | RenderCommands
    v
RenderPipeline.render(commands:)
```

### Module Dependency Direction

```
Depends on nothing:
  CppCore

Depends on CppCore:
  CppCoreSwift

Depends on CppCoreSwift + Apple frameworks:
  CoreEngine

Depends on CoreEngine:
  SnakePackage
  TetrisPackage
  MinesweeperPackage
  (future game packages)

Depends on CoreEngine + all game packages:
  App (offlineGamesApp)
```

### Effect Execution Timeline

```
Time ──────────────────────────────────────────────>

Action arrives          Effect executes           New action arrives
     |                       |                          |
     v                       v                          v
┌─────────┐  ┌───────────────────────────┐  ┌─────────┐
│ reduce() │  │ Effect.run { sleep; .tick }│  │ reduce() │
│ sync     │  │ async                      │  │ sync     │
└─────────┘  └───────────────────────────┘  └─────────┘
     |                                           |
     v                                           v
State updated                              State updated
Observers notified                         Observers notified
Frame rendered                             Frame rendered
```

---

## Summary

The architecture can be summarized in five rules:

1. **All state lives in the StateStore actor.** There is one store per game session. Nothing else holds mutable game state.
2. **State changes only through the reduce function.** Every mutation is the result of a dispatched Action processed by a pure function.
3. **Side effects are declared, not executed.** The reduce function returns Effect values. The StateStore interprets them.
4. **Rendering is a pure function of state.** `renderCommands(from:)` converts State to RenderCommands. The RenderPipeline draws them.
5. **Everything is Sendable.** Every type that crosses an isolation boundary conforms to Sendable, enforced by Swift 6 strict concurrency.
