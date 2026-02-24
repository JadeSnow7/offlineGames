[English](ModuleGuide.md) | [简体中文](ModuleGuide.zh-Hans.md)

# Module Guide: Adding a New Game

This guide walks through creating a new game module from scratch, using the project's TCA-style architecture. Every game is a self-contained Swift Package under `Packages/` that plugs into the shared engine.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Directory Structure](#directory-structure)
3. [Step 1: Create the SPM Package](#step-1-create-the-spm-package)
4. [Step 2: Define the State](#step-2-define-the-state)
5. [Step 3: Define Actions](#step-3-define-actions)
6. [Step 4: Write the Reducer](#step-4-write-the-reducer)
7. [Step 5: Implement Game Logic](#step-5-implement-game-logic)
8. [Step 6: Build the View Layer](#step-6-build-the-view-layer)
9. [Step 7: Implement GameDefinition](#step-7-implement-gamedefinition)
10. [Step 8: Register with GameRegistry](#step-8-register-with-gameregistry)
11. [Step 9: Add Configuration (Optional)](#step-9-add-configuration-optional)
12. [Complete Minimal Example](#complete-minimal-example)
13. [Testing](#testing)
14. [Checklist](#checklist)

---

## Prerequisites

- Xcode 26.0+ with Swift 6.1
- Familiarity with the project's unidirectional data flow:
  ```
  User Input -> Action -> Reducer(State, Action) -> (NewState, Effect)
  ```
- Read the existing `BlockPuzzle` or `SnakeGame` package for reference.

---

## Directory Structure

Every game module should follow this template layout:

```
Packages/MyNewGame/
├── Package.swift
├── Sources/
│   └── MyNewGame/
│       ├── MyNewGame.swift              # GameDefinition implementation
│       ├── State/
│       │   └── MyNewGameState.swift     # GameState conforming struct
│       ├── Action/
│       │   └── MyNewGameAction.swift    # Action enum
│       ├── Reducer/
│       │   └── MyNewGameReducer.swift   # Pure Reduce function
│       ├── Logic/
│       │   └── MyNewGameLogic.swift     # Helper logic (collision, scoring, etc.)
│       ├── View/
│       │   ├── MyNewGameView.swift      # Root SwiftUI view
│       │   └── MyNewGameBoardView.swift # Game board rendering
│       └── Configuration/
│           └── MyNewGameConfig.swift    # Difficulty settings, constants
└── Tests/
    └── MyNewGameTests/
        ├── MyNewGameReducerTests.swift
        └── MyNewGameLogicTests.swift
```

For simpler games, you may flatten the directory structure (as `BlockPuzzle` does), but the conceptual separation should still be maintained.

---

## Step 1: Create the SPM Package

Create `Packages/MyNewGame/Package.swift`:

```swift
// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "MyNewGame",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "MyNewGame", targets: ["MyNewGame"])
    ],
    dependencies: [
        .package(path: "../CoreEngine"),
        .package(path: "../GameUI")
    ],
    targets: [
        .target(
            name: "MyNewGame",
            dependencies: ["CoreEngine", "GameUI"]
        ),
        .testTarget(
            name: "MyNewGameTests",
            dependencies: ["MyNewGame"]
        )
    ]
)
```

Key points:
- Platform must be `.iOS(.v26)` to match the rest of the project.
- Always depend on `CoreEngine` (provides `GameState`, `Reduce`, `Effect`, `StateStore`, etc.).
- Always depend on `GameUI` (provides `AppTheme`, `GlassCard`, `GlassButton`, shared components).
- If you need C++ algorithms (collision, pathfinding), add a dependency on `CppCore`.
- If you need Metal rendering, add a dependency on `MetalRenderer`.

---

## Step 2: Define the State

Create a struct that conforms to the `GameState` protocol from `CoreEngine`.

The `GameState` protocol requires three properties:

```swift
public protocol GameState: Sendable, Equatable {
    var isRunning: Bool { get }
    var score: Int { get }
    var isGameOver: Bool { get }
}
```

Example implementation:

```swift
import CoreEngine

public struct MyNewGameState: GameState, Equatable, Sendable {
    // Required by GameState
    public var isRunning: Bool
    public var score: Int
    public var isGameOver: Bool

    // Game-specific state
    public var level: Int
    public var playerPosition: CGPoint
    public var timeRemaining: Double

    public init() {
        self.isRunning = false
        self.score = 0
        self.isGameOver = false
        self.level = 1
        self.playerPosition = .zero
        self.timeRemaining = 60.0
    }
}
```

Guidelines:
- State must be a **value type** (struct).
- State must conform to `Sendable` and `Equatable`.
- Keep state minimal -- only store what is needed to fully describe the game at any moment.
- Use `init()` to set reasonable defaults for a fresh game.

---

## Step 3: Define Actions

Create an enum listing every possible event or user interaction.

```swift
import CoreEngine

public enum MyNewGameAction: Sendable {
    // Lifecycle
    case start
    case pause
    case resume
    case reset

    // Game loop
    case tick(delta: Double)

    // User input
    case tap(x: Float, y: Float)
    case swipe(direction: Direction)

    // Internal
    case spawnEnemy
    case scorePoint(Int)
}
```

Guidelines:
- Actions must be `Sendable`.
- Actions should be **descriptive of what happened**, not what should happen. Prefer `case userTappedPlay` over `case startTheGame`.
- Group actions by category with comments.
- Associated values should be value types.

---

## Step 4: Write the Reducer

The reducer is a pure function with the signature:

```swift
public typealias Reduce<State: Sendable, Action: Sendable> =
    @Sendable (State, Action) -> (State, Effect<Action>)
```

It takes the current state and an action, and returns the new state plus any side effects.

```swift
import CoreEngine

public let myNewGameReducer: Reduce<MyNewGameState, MyNewGameAction> = { state, action in
    var newState = state

    switch action {
    case .start:
        newState = MyNewGameState()
        newState.isRunning = true
        return (newState, .none)

    case .pause:
        newState.isRunning = false
        return (newState, .none)

    case .resume:
        newState.isRunning = true
        return (newState, .none)

    case .reset:
        return (MyNewGameState(), .none)

    case .tick(let delta):
        guard state.isRunning, !state.isGameOver else {
            return (state, .none)
        }
        newState.timeRemaining -= delta
        if newState.timeRemaining <= 0 {
            newState.isGameOver = true
            newState.isRunning = false
        }
        return (newState, .none)

    case .tap(let x, let y):
        newState.playerPosition = CGPoint(x: CGFloat(x), y: CGFloat(y))
        newState.score += 10
        return (newState, .none)

    case .swipe(let direction):
        // Move player in direction
        return (newState, .none)

    case .spawnEnemy:
        // Add enemy to state
        return (newState, .none)

    case .scorePoint(let points):
        newState.score += points
        return (newState, .none)
    }
}
```

Guidelines:
- **Pure function** -- no side effects in the reducer itself. All side effects go through `Effect`.
- Copy the state with `var newState = state`, mutate the copy, return it.
- Return `.none` when no side effects are needed.
- For effects that produce follow-up actions, use `.run`:
  ```swift
  return (newState, .run {
      try await Task.sleep(for: .seconds(2.0))
      return .spawnEnemy
  })
  ```
- For fire-and-forget effects (sound, haptics), use `.fireAndForget`:
  ```swift
  return (newState, .fireAndForget {
      await AudioEngine.shared.play(.scoreUp)
  })
  ```

---

## Step 5: Implement Game Logic

Extract complex game logic into dedicated helper functions or types in the `Logic/` directory. Keep the reducer thin by delegating:

```swift
// Logic/MyNewGameLogic.swift

import CoreEngine

enum MyNewGameLogic {
    /// Check if the player has collided with any enemy.
    static func checkCollisions(
        playerPosition: CGPoint,
        enemies: [Enemy]
    ) -> Bool {
        // Collision logic here
        return false
    }

    /// Calculate score multiplier based on level.
    static func scoreMultiplier(for level: Int) -> Int {
        min(level, 10)
    }
}
```

Then call from the reducer:

```swift
case .tick(let delta):
    if MyNewGameLogic.checkCollisions(
        playerPosition: newState.playerPosition,
        enemies: newState.enemies
    ) {
        newState.isGameOver = true
    }
    return (newState, .none)
```

---

## Step 6: Build the View Layer

Build your UI with SwiftUI, using the shared `GameUI` components for consistent styling.

```swift
import SwiftUI
import CoreEngine
import GameUI

struct MyNewGameView: View {
    let store: StateStore<MyNewGameState, MyNewGameAction>
    @State private var gameState = MyNewGameState()

    var body: some View {
        ZStack {
            // Game board
            MyNewGameBoardView(state: gameState)

            // HUD overlay
            VStack {
                HStack {
                    Text("Score: \(gameState.score)")
                        .font(AppTheme.scoreFont)
                    Spacer()
                    Text("Time: \(Int(gameState.timeRemaining))")
                        .font(AppTheme.scoreFont)
                }
                .padding(AppTheme.padding)

                Spacer()

                if gameState.isGameOver {
                    GlassCard {
                        VStack(spacing: 12) {
                            Text("Game Over")
                                .font(AppTheme.titleFont)
                            Text("Score: \(gameState.score)")
                                .font(AppTheme.bodyFont)
                            GlassButton("Play Again") {
                                Task { await store.send(.reset) }
                                Task { await store.send(.start) }
                            }
                        }
                    }
                }
            }
        }
        .task {
            await store.subscribe { newState in
                gameState = newState
            }
            await store.send(.start)
        }
    }
}
```

Guidelines:
- Use `AppTheme` constants for fonts, colors, spacing, and corner radii.
- Use `GlassCard` and `GlassButton` for the iOS 26 Liquid Glass look.
- Subscribe to the store to get state updates.
- Dispatch actions via `await store.send(...)`.

---

## Step 7: Implement GameDefinition

The `GameDefinition` protocol is how your game registers with the catalog:

```swift
public protocol GameDefinition: Sendable {
    var metadata: GameMetadata { get }
    @MainActor func makeRootView() -> AnyView
}
```

Implement it in your module's root file:

```swift
import SwiftUI
import CoreEngine
import GameCatalog

public struct MyNewGameDefinition: GameDefinition {
    public let metadata = GameMetadata(
        id: "my-new-game",
        displayName: "My New Game",
        description: "A fun new game with original mechanics.",
        iconName: "gamecontroller.fill",   // SF Symbol
        accentColor: .green,
        minAge: 4,
        category: .action
    )

    public init() {}

    @MainActor
    public func makeRootView() -> AnyView {
        let store = StateStore(
            initialState: MyNewGameState(),
            reducer: myNewGameReducer
        )
        return AnyView(MyNewGameView(store: store))
    }
}
```

Available categories: `.action`, `.puzzle`, `.classic`, `.reflex`.

---

## Step 8: Register with GameRegistry

In the main app target (`App/`), register your game at launch. The `GameRegistry` is an actor:

```swift
public actor GameRegistry {
    public func register(_ game: GameDefinition)
    public var allMetadata: [GameMetadata] { get }
    public func game(withID id: String) -> GameDefinition?
}
```

Add registration in the app's initialization code:

```swift
await registry.register(MyNewGameDefinition())
```

Then add your package as a dependency in the app target's `Package.swift` or Xcode project settings.

---

## Step 9: Add Configuration (Optional)

For games with difficulty levels or tunable parameters, create a configuration struct:

```swift
// Configuration/MyNewGameConfig.swift

public struct MyNewGameConfig: Sendable {
    public let initialTime: Double
    public let pointsPerTap: Int
    public let enemySpawnInterval: Double

    public static let easy = MyNewGameConfig(
        initialTime: 90,
        pointsPerTap: 10,
        enemySpawnInterval: 3.0
    )

    public static let normal = MyNewGameConfig(
        initialTime: 60,
        pointsPerTap: 10,
        enemySpawnInterval: 2.0
    )

    public static let hard = MyNewGameConfig(
        initialTime: 30,
        pointsPerTap: 5,
        enemySpawnInterval: 1.0
    )
}
```

Pass the config into your state's initializer and use it in the reducer.

---

## Complete Minimal Example

Below is a complete, compilable game module -- a simple "Tap Counter" game that counts taps within a time limit.

### Package.swift

```swift
// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "TapCounter",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "TapCounter", targets: ["TapCounter"])
    ],
    dependencies: [
        .package(path: "../CoreEngine"),
        .package(path: "../GameUI"),
        .package(path: "../GameCatalog")
    ],
    targets: [
        .target(
            name: "TapCounter",
            dependencies: ["CoreEngine", "GameUI", "GameCatalog"]
        ),
        .testTarget(
            name: "TapCounterTests",
            dependencies: ["TapCounter"]
        )
    ]
)
```

### Sources/TapCounter/TapCounterState.swift

```swift
import CoreEngine

public struct TapCounterState: GameState, Equatable, Sendable {
    public var isRunning: Bool = false
    public var score: Int = 0
    public var isGameOver: Bool = false
    public var timeRemaining: Double = 10.0

    public init() {}
}
```

### Sources/TapCounter/TapCounterAction.swift

```swift
public enum TapCounterAction: Sendable {
    case start
    case reset
    case tap
    case tick(delta: Double)
}
```

### Sources/TapCounter/TapCounterReducer.swift

```swift
import CoreEngine

public let tapCounterReducer: Reduce<TapCounterState, TapCounterAction> = { state, action in
    var s = state
    switch action {
    case .start:
        s = TapCounterState()
        s.isRunning = true
        return (s, .none)

    case .reset:
        return (TapCounterState(), .none)

    case .tap:
        guard s.isRunning else { return (s, .none) }
        s.score += 1
        return (s, .none)

    case .tick(let delta):
        guard s.isRunning else { return (s, .none) }
        s.timeRemaining -= delta
        if s.timeRemaining <= 0 {
            s.timeRemaining = 0
            s.isRunning = false
            s.isGameOver = true
        }
        return (s, .none)
    }
}
```

### Sources/TapCounter/TapCounterView.swift

```swift
import SwiftUI
import CoreEngine
import GameUI

struct TapCounterView: View {
    let store: StateStore<TapCounterState, TapCounterAction>
    @State private var state = TapCounterState()

    var body: some View {
        VStack(spacing: AppTheme.padding) {
            Text("Time: \(String(format: "%.1f", state.timeRemaining))")
                .font(AppTheme.scoreFont)

            Text("\(state.score)")
                .font(.system(size: 80, weight: .bold, design: .monospaced))

            if state.isGameOver {
                GlassCard {
                    VStack(spacing: 12) {
                        Text("Time's Up!").font(AppTheme.titleFont)
                        Text("You tapped \(state.score) times.")
                        GlassButton("Play Again") {
                            Task { await store.send(.start) }
                        }
                    }
                }
            } else if state.isRunning {
                GlassButton("TAP!") {
                    Task { await store.send(.tap) }
                }
                .frame(width: 200, height: 200)
            } else {
                GlassButton("Start") {
                    Task { await store.send(.start) }
                }
            }
        }
        .task {
            await store.subscribe { newState in
                state = newState
            }
        }
    }
}
```

### Sources/TapCounter/TapCounter.swift

```swift
import SwiftUI
import CoreEngine
import GameCatalog

public struct TapCounterDefinition: GameDefinition {
    public let metadata = GameMetadata(
        id: "tap-counter",
        displayName: "Tap Counter",
        description: "Tap as fast as you can before time runs out!",
        iconName: "hand.tap.fill",
        accentColor: .orange,
        minAge: 4,
        category: .reflex
    )

    public init() {}

    @MainActor
    public func makeRootView() -> AnyView {
        let store = StateStore(
            initialState: TapCounterState(),
            reducer: tapCounterReducer
        )
        return AnyView(TapCounterView(store: store))
    }
}
```

### Tests/TapCounterTests/TapCounterReducerTests.swift

```swift
import Testing
@testable import TapCounter
import CoreEngine

@Test func tapIncrementsScore() {
    let initial = TapCounterState()
    var state = initial
    state.isRunning = true
    let (newState, _) = tapCounterReducer(state, .tap)
    #expect(newState.score == 1)
}

@Test func tickDecrementsTime() {
    var state = TapCounterState()
    state.isRunning = true
    state.timeRemaining = 5.0
    let (newState, _) = tapCounterReducer(state, .tick(delta: 1.0))
    #expect(newState.timeRemaining == 4.0)
}

@Test func gameOverWhenTimeExpires() {
    var state = TapCounterState()
    state.isRunning = true
    state.timeRemaining = 0.5
    let (newState, _) = tapCounterReducer(state, .tick(delta: 1.0))
    #expect(newState.isGameOver)
    #expect(!newState.isRunning)
}

@Test func tapIgnoredWhenNotRunning() {
    let state = TapCounterState()
    let (newState, _) = tapCounterReducer(state, .tap)
    #expect(newState.score == 0)
}
```

---

## Testing

Because reducers are pure functions, they are trivially testable:

```swift
let (newState, effect) = myReducer(initialState, .someAction)
#expect(newState.someProperty == expectedValue)
```

Test priorities:
1. **Reducer tests** -- highest value, pure logic.
2. **Logic helper tests** -- unit test extracted algorithms.
3. **State invariant tests** -- verify state never enters invalid combinations.

---

## Checklist

Before submitting your new game module:

- [ ] `Package.swift` compiles with `swift build --package-path Packages/MyNewGame`
- [ ] State struct conforms to `GameState`, `Sendable`, `Equatable`
- [ ] Action enum conforms to `Sendable`
- [ ] Reducer is a pure function with no side effects
- [ ] Effects are used for all async/side-effectful operations
- [ ] `GameDefinition` is implemented with complete `GameMetadata`
- [ ] Game is registered with `GameRegistry` in the app target
- [ ] Views use `AppTheme`, `GlassCard`, and `GlassButton` from `GameUI`
- [ ] All art, sound, and music assets are original or properly licensed
- [ ] Game name and metadata do not reference any trademarked names
- [ ] Reducer tests are written and passing
- [ ] Game works in both portrait and landscape orientations
- [ ] Game respects accessibility settings (Dynamic Type, VoiceOver)
