# Coding Standards

## Table of Contents

1. [File and Module Organization](#file-and-module-organization)
2. [Type Declaration Rules](#type-declaration-rules)
3. [Pure Functions and the Effect Type](#pure-functions-and-the-effect-type)
4. [Actor Isolation and Shared Mutable State](#actor-isolation-and-shared-mutable-state)
5. [Swift 6 Strict Concurrency](#swift-6-strict-concurrency)
6. [Optionals and Safety](#optionals-and-safety)
7. [Game Template Structure](#game-template-structure)
8. [Naming Conventions](#naming-conventions)
9. [Dependency Policy](#dependency-policy)
10. [C++ Code Standards](#c-code-standards)
11. [SwiftLint Rules](#swiftlint-rules)
12. [Error Handling](#error-handling)
13. [Testing Requirements](#testing-requirements)

---

## File and Module Organization

### One File, One Responsibility

Every source file has exactly one primary responsibility. A file should be small enough to understand in its entirety without scrolling extensively. If a file grows beyond approximately 200 lines, consider whether it can be split.

```
Good:
  SnakeState.swift          -- defines SnakeState struct
  SnakeAction.swift         -- defines SnakeAction enum
  SnakeReducer.swift        -- defines snakeReducer function
  SnakeLogic.swift          -- defines pure helper functions for snake movement
  FoodSpawner.swift         -- defines food spawning logic

Bad:
  SnakeGame.swift           -- contains state, action, reducer, and logic all in one file
  Helpers.swift             -- grab-bag of unrelated utility functions
  Models.swift              -- multiple unrelated types in one file
```

### Package = Module = Bounded Context

Each Swift package corresponds to one conceptual module with a clear boundary. Packages expose a minimal public API and keep implementation details `internal` or `private`.

```
Packages/
  CoreEngine/              -- shared architecture primitives
  CppCore/                 -- C++ algorithms
  CppCoreSwift/            -- Swift overlay for CppCore
  SnakePackage/            -- everything related to the Snake game
  TetrisPackage/           -- everything related to Tetris
  MinesweeperPackage/      -- everything related to Minesweeper
```

### Import Discipline

- Import only what you need. Prefer `import CoreEngine` over `import Foundation` when only CoreEngine types are used.
- Never use `@_exported import`. Each file explicitly imports its dependencies.
- Order imports alphabetically: Apple frameworks first, then project packages.

```swift
import CoreEngine
import SwiftUI

// Not:
import SwiftUI
import Foundation   // unnecessary if CoreEngine re-exports what you need
import CoreEngine
```

---

## Type Declaration Rules

### Every Public Type Gets Its Own File

If a type is `public`, it must be the sole primary declaration in its file, and the file must be named after the type.

```
Public struct SnakeState   -> SnakeState.swift
Public enum SnakeAction    -> SnakeAction.swift
Public protocol RenderPipeline -> RenderPipeline.swift
Public actor AudioActor    -> AudioActor.swift
```

Small private helper types may be defined in the same file as the public type they support, but only if they are tightly coupled and would not be useful elsewhere.

```swift
// SnakeState.swift

/// The complete state of a Snake game session.
public struct SnakeState: Sendable, Equatable {
    public var snake: Snake
    public var food: Food
    public var score: Int
    public var phase: GamePhase
    public var direction: Direction
    public var gridSize: GridSize
    public var speed: Speed
}

// This private helper is tightly coupled to SnakeState and used nowhere else.
private extension SnakeState {
    var isAlive: Bool { phase == .playing }
}
```

### Struct by Default

Use `struct` unless you have a specific reason for another type:

| Type | When to Use |
|------|-------------|
| `struct` | Default. All state types, configuration, value objects. |
| `enum` | Closed set of cases: actions, render commands, phases. |
| `actor` | Shared mutable state that must be thread-safe. |
| `class` | Only when required by framework APIs (e.g., `UIViewController` subclass). |
| `protocol` | When multiple implementations of an interface exist (e.g., `RenderPipeline`). |

Never use `class` for model types. Never use `class` for state. If you think you need reference semantics, use an actor.

---

## Pure Functions and the Effect Type

### Pure Functions Preferred

A pure function depends only on its parameters and produces output only through its return value. It does not read or write global state, perform I/O, or trigger side effects.

All game logic functions must be pure:

```swift
// GOOD: Pure function. Easy to test, easy to reason about.
func advance(snake: Snake, direction: Direction, gridSize: GridSize) -> MoveResult {
    let newHead = snake.head.moved(in: direction)
    guard gridSize.contains(newHead) else { return .collision }
    guard !snake.body.contains(newHead) else { return .collision }
    return .moved(Snake(segments: [newHead] + snake.segments.dropLast()))
}

// BAD: Reads and writes shared mutable state. Impossible to test in isolation.
func advance() {
    let newHead = gameState.snake.head.moved(in: gameState.direction)
    if gameState.gridSize.contains(newHead) {
        gameState.snake = Snake(segments: [newHead] + gameState.snake.segments.dropLast())
    } else {
        gameState.phase = .gameOver
        audioPlayer.play("gameover.wav")  // side effect!
    }
}
```

### Side Effects Through the Effect Type Only

When game logic needs to interact with the outside world (play audio, trigger haptics, set a timer, persist data), it must return an `Effect` value from the reducer. The reducer itself never executes side effects.

```swift
// GOOD: Side effect declared as a value, executed by the StateStore.
case .scorePoint:
    state.score += 1
    return (state, .batch([
        .fireAndForget { await AudioActor.shared.play(.point) },
        .fireAndForget { await HapticActor.shared.trigger(.light) }
    ]))

// BAD: Side effect executed directly in the reducer.
case .scorePoint:
    state.score += 1
    AudioActor.shared.play(.point)  // WRONG: side effect in reducer
    return (state, .none)
```

### Effect Composition

Build reusable effect helpers for common patterns:

```swift
/// Play a sound and trigger a haptic simultaneously.
func feedback<A: Sendable>(
    sound: SoundEffect,
    haptic: HapticPattern
) -> Effect<A> {
    .batch([
        .fireAndForget { await AudioActor.shared.play(sound) },
        .fireAndForget { await HapticActor.shared.trigger(haptic) }
    ])
}

/// Schedule the next game tick after a delay.
func scheduleTick(after interval: Duration) -> Effect<SnakeAction> {
    .run {
        try? await Task.sleep(for: interval)
        return .tick
    }
}
```

---

## Actor Isolation and Shared Mutable State

### Rule: All Shared Mutable State Must Be an Actor

If a piece of mutable state is accessed from more than one concurrency domain, it must be an `actor`. No exceptions. No classes with locks. No `DispatchQueue`-based synchronization. No `@unchecked Sendable`.

```swift
// GOOD: Shared mutable state in an actor.
public actor ScoreStore {
    private var highScores: [GameID: Int] = [:]

    public func record(score: Int, for game: GameID) {
        if score > (highScores[game] ?? 0) {
            highScores[game] = score
        }
    }

    public func highScore(for game: GameID) -> Int {
        highScores[game] ?? 0
    }
}

// BAD: Shared mutable state in a class with a lock.
class ScoreStore {
    private let lock = NSLock()
    private var highScores: [GameID: Int] = [:]

    func record(score: Int, for game: GameID) {
        lock.lock()
        defer { lock.unlock() }
        // ...
    }
}
```

### Actor Granularity

Each actor should manage one cohesive piece of state:

| Actor | Responsibility |
|-------|---------------|
| `StateStore` | Game session state and reduce loop |
| `GameLoop` | Tick timing and loop control |
| `AudioActor` | Audio engine, buffers, playback |
| `HapticActor` | Haptic engine and patterns |
| `ScoreStore` | High score persistence |
| `SettingsStore` | User preferences |

Do not combine unrelated state into a single actor. A "god actor" is as bad as a "god object."

### Avoiding Actor Reentrancy Issues

Be aware that `await` inside an actor method is a suspension point where other calls may interleave. Design actor methods to be short and avoid multiple suspension points when possible.

```swift
// CAUTION: Two suspension points. State may change between them.
public func processAndSave(action: Action) async {
    let result = await heavyComputation(action)  // suspension 1
    await persistenceActor.save(result)           // suspension 2
    // By this point, self.state may have been modified by another call.
}

// BETTER: Minimize suspension points. Do local work synchronously.
public func processAndSave(action: Action) {
    let result = computeLocally(action)  // synchronous, no suspension
    Task {
        await persistenceActor.save(result)  // fire and forget
    }
}
```

---

## Swift 6 Strict Concurrency

### All Types Must Be Sendable

Every type that crosses an isolation boundary must conform to `Sendable`. Under Swift 6 strict concurrency (enabled in all packages), the compiler enforces this.

```swift
// GOOD: Value types are automatically Sendable.
public struct SnakeState: Sendable, Equatable {
    public var snake: Snake
    public var food: Food
    public var score: Int
}

// GOOD: Enums with Sendable associated values are Sendable.
public enum SnakeAction: Sendable {
    case tick
    case changeDirection(Direction)
    case startGame
    case pauseGame
}

// GOOD: Actors are inherently Sendable.
public actor AudioActor: Sendable { ... }

// BAD: Class is not Sendable. Use struct or actor instead.
public class GameState {
    var score: Int = 0  // mutable reference type = not Sendable
}
```

### Strict Concurrency Compiler Settings

Every `Package.swift` must enable strict concurrency checking:

```swift
swiftSettings: [
    .swiftLanguageMode(.v6)
]
```

### No @unchecked Sendable

Never use `@unchecked Sendable` to silence the compiler. If the compiler says a type is not Sendable, fix the type, do not suppress the warning. The only permitted exception is when wrapping a framework type that is known to be thread-safe but lacks a Sendable conformance (e.g., certain Core Foundation types), and even then it must be documented with a comment explaining why it is safe.

### Global State

Global mutable state is prohibited. Global `let` constants are fine because they are immutable.

```swift
// GOOD: Immutable global constant.
public let maxGridSize = GridSize(width: 30, height: 30)

// GOOD: Actor singleton for shared mutable state.
public actor AudioActor {
    public static let shared = AudioActor()
}

// BAD: Mutable global variable.
public var currentScore = 0  // data race waiting to happen
```

---

## Optionals and Safety

### No Force Unwraps

Force unwraps (`!`) are prohibited in all production code. Every optional must be safely unwrapped.

```swift
// GOOD
guard let device = MTLCreateSystemDefaultDevice() else {
    fatalError("Metal is not supported on this device")
    // fatalError is acceptable here because the app literally cannot run without Metal.
}

if let highScore = scores[gameID] {
    displayScore(highScore)
}

let name = player.name ?? "Unknown"

// BAD
let device = MTLCreateSystemDefaultDevice()!
let highScore = scores[gameID]!
```

The sole exception is `fatalError` with a descriptive message for truly impossible states (e.g., a required system resource is unavailable at launch). This is preferred over a force unwrap because it provides a clear error message.

### No Implicitly Unwrapped Optionals

Implicitly unwrapped optionals (`Type!`) are prohibited. They exist to support two-phase initialization patterns that should be avoided.

```swift
// BAD
var engine: CHHapticEngine!

// GOOD: Make it a real optional and handle the nil case.
var engine: CHHapticEngine?

// GOOD: Or initialize it at declaration time.
let engine: CHHapticEngine = try CHHapticEngine()

// GOOD: Or use lazy initialization.
lazy var engine: CHHapticEngine = {
    try! CHHapticEngine()  // only acceptable in a lazy var where failure = programmer error
}()
```

### Optional Chaining Preferred

When accessing nested optionals, use optional chaining rather than nested `if let`:

```swift
// GOOD
let score = gameSession?.state.score ?? 0

// VERBOSE (acceptable but not preferred for simple access)
if let session = gameSession {
    let score = session.state.score
    displayScore(score)
}
```

---

## Game Template Structure

Every game package follows a standard directory structure. This consistency makes it easy to navigate any game package without prior familiarity.

```
Packages/
  SnakePackage/
    Sources/
      SnakePackage/
        State/
          SnakeState.swift          -- The complete game state struct
          Snake.swift               -- Snake value type (segments, head, body)
          Food.swift                -- Food value type (position, points, type)
          GridSize.swift            -- Grid dimensions
          Speed.swift               -- Tick interval configuration
          GamePhase.swift           -- enum: menu, playing, paused, gameOver
        Action/
          SnakeAction.swift         -- All actions the game can process
        Reducer/
          SnakeReducer.swift        -- The reduce function
        Logic/
          SnakeLogic.swift          -- Pure functions for snake movement
          FoodSpawner.swift         -- Pure function for food placement
          CollisionDetection.swift  -- Pure functions for collision checks
          ScoreCalculator.swift     -- Pure function for score computation
        View/
          SnakeGameView.swift       -- Main SwiftUI game view
          SnakeGridView.swift       -- Grid rendering subview
          SnakeOverlayView.swift    -- Pause/game-over overlay
          SnakeMenuView.swift       -- Pre-game menu
        Configuration/
          SnakeConfiguration.swift  -- Difficulty, grid size, speed presets
          SnakeAssets.swift         -- Asset catalog references
          SnakeColors.swift         -- Color palette
    Tests/
      SnakePackageTests/
        SnakeReducerTests.swift     -- Tests for every action/state transition
        SnakeLogicTests.swift       -- Tests for movement and collision logic
        FoodSpawnerTests.swift      -- Tests for food placement
        ScoreCalculatorTests.swift  -- Tests for score computation
```

### Directory Responsibilities

| Directory | Contents | Rules |
|-----------|----------|-------|
| `State/` | All value types that compose the game state. | All types must be `Sendable` and `Equatable`. No logic, only data. |
| `Action/` | The action enum and any associated types. | One enum with all possible actions. Must be `Sendable`. |
| `Reducer/` | The reduce function. | Exactly one public function. Must be pure. |
| `Logic/` | Pure helper functions called by the reducer. | No imports of UIKit, SwiftUI, or rendering frameworks. All functions are free functions or static methods. |
| `View/` | SwiftUI views for the game. | Views observe state and dispatch actions. No game logic in views. |
| `Configuration/` | Constants, presets, asset references. | All values are `let` constants or static properties. |

### State Directory Rules

- Every property in the state struct must be a value type.
- The state struct must conform to `Sendable` and `Equatable`.
- Derived properties (computed from other state) should be computed properties, not stored.
- No optionals in state unless the absence of a value is semantically meaningful (e.g., `var activePowerUp: PowerUp?` is fine; `var score: Int?` is not -- use `var score: Int = 0`).

### Logic Directory Rules

- No side effects. Every function is pure.
- No imports of Apple UI frameworks.
- Functions should be `static` methods on a namespace enum or free functions.
- Functions receive all needed data through parameters, never accessing global state.

```swift
// GOOD: Pure, testable, takes all inputs as parameters.
enum SnakeLogic {
    static func advance(
        snake: Snake,
        direction: Direction,
        gridSize: GridSize
    ) -> MoveResult {
        let newHead = snake.head.moved(in: direction)
        guard gridSize.contains(newHead) else { return .collision }
        guard !snake.body.contains(newHead) else { return .collision }
        let newSegments = [newHead] + snake.segments.dropLast()
        return .moved(Snake(segments: newSegments))
    }
}
```

---

## Naming Conventions

### Swift Naming

| Element | Convention | Example |
|---------|-----------|---------|
| Types (struct, enum, actor, class, protocol) | PascalCase | `SnakeState`, `GamePhase`, `RenderPipeline` |
| Functions and methods | camelCase | `advance(snake:direction:)`, `renderCommands(from:)` |
| Variables and properties | camelCase | `currentScore`, `gridSize`, `isAlive` |
| Constants (let) | camelCase | `maxGridWidth`, `defaultTickInterval` |
| Enum cases | camelCase | `.playing`, `.gameOver`, `.changeDirection` |
| Boolean properties | Reads as a question | `isAlive`, `hasFood`, `canMove`, `shouldRender` |
| Type parameters | Single uppercase letter or PascalCase | `<State>`, `<Action>`, `<T>` |
| File names | Match the primary type | `SnakeState.swift`, `GameLoop.swift` |

### Specific Naming Patterns

**State types**: `{Game}State` -- e.g., `SnakeState`, `TetrisState`, `MinesweeperState`.

**Action types**: `{Game}Action` -- e.g., `SnakeAction`, `TetrisAction`.

**Reducer functions**: `{game}Reducer` (camelCase) -- e.g., `snakeReducer`, `tetrisReducer`.

**Logic namespaces**: `{Game}Logic` -- e.g., `SnakeLogic`, `TetrisLogic`.

**View types**: `{Game}{Purpose}View` -- e.g., `SnakeGameView`, `SnakeGridView`, `TetrisMenuView`.

**Configuration types**: `{Game}Configuration` -- e.g., `SnakeConfiguration`.

### Abbreviation Policy

- Do not abbreviate words in public APIs. Use `position` not `pos`, `direction` not `dir`, `configuration` not `config`.
- Standard Apple abbreviations are allowed: `URL`, `ID`, `RGB`, `AABB`.
- Single-letter variable names are allowed only for: loop indices (`i`, `j`), closures with obvious context (`$0`), and generic type parameters (`T`).

```swift
// GOOD
let gridPosition = Position(x: 5, y: 10)
let moveDirection: Direction = .up
let tickInterval: Duration = .milliseconds(100)

// BAD
let gridPos = Position(x: 5, y: 10)
let moveDir: Direction = .up
let tickInt: Duration = .milliseconds(100)
```

### Argument Labels

Follow the Swift API Design Guidelines. Method names read as English phrases at the call site:

```swift
// GOOD: Reads naturally.
snake.moved(in: .up)
grid.contains(position)
FoodSpawner.spawn(avoiding: occupiedPositions, in: gridSize)

// BAD: Redundant or unclear labels.
snake.move(direction: .up)
grid.containsPosition(position)
FoodSpawner.spawnFood(avoidingPositions: occupiedPositions, inGrid: gridSize)
```

---

## Dependency Policy

### No Third-Party Dependencies

The project uses zero third-party Swift packages. Every dependency is either:

1. An Apple framework (SwiftUI, Metal, SpriteKit, AVFoundation, CoreHaptics, GameController).
2. An internal package within this repository (CoreEngine, CppCore, CppCoreSwift, game packages).

### Rationale

- **Stability** -- No risk of a dependency being abandoned, introducing breaking changes, or being compromised.
- **Build times** -- No dependency resolution, no downloading, no version conflicts.
- **Understanding** -- Every line of code is authored by the team and understood by the team.
- **Binary size** -- No unused code from large frameworks included in the binary.
- **Offline development** -- The project builds without an internet connection.

### What This Means in Practice

- Need JSON encoding? Use `Codable` (Foundation).
- Need networking? Use `URLSession` (Foundation).
- Need a test assertion library? Use `XCTest` with custom helpers.
- Need dependency injection? Use protocol-based injection; no container frameworks.
- Need reactive state observation? Use `AsyncStream` and `@Observable`.
- Need image loading? Use `UIImage` / `NSImage` (UIKit/AppKit).

If a task seems to require a third-party library, reconsider the approach. The solution using Apple frameworks may be simpler than expected.

---

## C++ Code Standards

### File Organization

- Headers in `include/cppcore/` with `.hpp` extension.
- Implementation files (if any) in `src/` with `.cpp` extension.
- Prefer header-only implementations for simple algorithms.

### Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Functions | snake_case | `bfs_path`, `aabb_circle_intersect` |
| Types (struct, class) | PascalCase | `Vec2`, `AABB`, `GridPos` |
| Namespaces | lowercase single word | `cppcore` |
| Member variables | snake_case | `grid_width`, `max_depth` |
| Constants / macros | UPPER_SNAKE_CASE | `MAX_GRID_SIZE`, `PI` |
| Template parameters | PascalCase | `<typename T>`, `<typename Comparator>` |
| File names | snake_case | `vec2.hpp`, `collision.hpp`, `grid.hpp` |

### Namespace

All C++ code lives in the `cppcore` namespace. No code at global scope.

```cpp
// GOOD
namespace cppcore {
    struct Vec2 { float x; float y; };
}

// BAD: Pollutes global namespace.
struct Vec2 { float x; float y; };
```

### Modern C++ Practices

- Use C++17 or later.
- Prefer `struct` with public members for plain data types.
- Use `const` everywhere possible: `const` parameters, `const` member functions, `const` local variables.
- No raw `new`/`delete`. Use stack allocation or standard containers.
- No C-style casts. Use `static_cast`, `reinterpret_cast` (sparingly), or constructor syntax.
- Use `#pragma once` instead of include guards.
- Use `std::vector`, `std::array`, `std::optional`, `std::string_view` from the standard library.
- No exceptions. Functions that can fail return `std::optional` or use output parameters.

```cpp
// GOOD
#pragma once
#include <vector>
#include <optional>

namespace cppcore {

struct GridPos {
    int x;
    int y;
};

std::optional<GridPos> find_nearest_empty(
    const std::vector<bool>& grid,
    int width,
    int height,
    const GridPos& from
);

} // namespace cppcore
```

### Swift Interop Considerations

- Keep C++ types simple. Swift interop works best with structs that have public members and simple constructors.
- Avoid C++ features that do not bridge well: templates (other than in implementation details), multiple inheritance, operator overloads beyond arithmetic.
- Every type that will be used from Swift must be defined in a public header included in the module map.

---

## SwiftLint Rules

The project uses SwiftLint to enforce a baseline of style consistency. The following rules are enabled and enforced in CI.

### Enforced Rules

| Rule | Description | Example (violation) |
|------|-------------|-------------------|
| `force_unwrapping` | No force unwraps (`!`) | `let x = optional!` |
| `implicitly_unwrapped_optional` | No `Type!` declarations | `var x: String!` |
| `force_cast` | No `as!` casts | `let x = y as! Int` |
| `line_length` | Max 120 characters per line | (long lines) |
| `file_length` | Max 400 lines per file | (long files) |
| `function_body_length` | Max 50 lines per function body | (long functions) |
| `type_body_length` | Max 300 lines per type body | (long type declarations) |
| `cyclomatic_complexity` | Max 10 per function | (deeply nested logic) |
| `nesting` | Max 2 levels of type nesting | (structs inside structs inside structs) |
| `identifier_name` | 3-character minimum, 50-character max | `let x = 5` (too short, unless it is a loop index) |
| `trailing_whitespace` | No trailing whitespace | (invisible characters at end of line) |
| `vertical_whitespace` | Max 1 consecutive blank line | (multiple blank lines) |
| `trailing_comma` | Trailing comma in multi-line collections | `[1, 2, 3]` (no trailing comma) |
| `unused_import` | No unused imports | `import Foundation` (when nothing from Foundation is used) |
| `redundant_optional_initialization` | No `var x: Int? = nil` | `var x: Int? = nil` |
| `empty_count` | Use `.isEmpty` instead of `.count == 0` | `array.count == 0` |
| `first_where` | Use `.first(where:)` instead of `.filter().first` | `array.filter { $0 > 5 }.first` |
| `sorted_first_last` | Use `.min()` / `.max()` instead of `.sorted().first` / `.sorted().last` | `array.sorted().first` |

### SwiftLint Configuration Excerpt

```yaml
# .swiftlint.yml

disabled_rules:
  - todo  # We allow TODO comments during development

opt_in_rules:
  - force_unwrapping
  - implicitly_unwrapped_optional
  - empty_count
  - first_where
  - sorted_first_last
  - unused_import
  - trailing_comma

force_unwrapping:
  severity: error

implicitly_unwrapped_optional:
  severity: error

force_cast:
  severity: error

line_length:
  warning: 120
  error: 150
  ignores_comments: true
  ignores_urls: true

file_length:
  warning: 400
  error: 600

function_body_length:
  warning: 50
  error: 80

type_body_length:
  warning: 300
  error: 500

cyclomatic_complexity:
  warning: 10
  error: 15

identifier_name:
  min_length:
    warning: 3
    error: 2
  max_length:
    warning: 50
    error: 60
  excluded:
    - id
    - x
    - y
    - i
    - j

excluded:
  - .build
  - Packages/CppCore
```

---

## Error Handling

### Use Swift's Error Handling, Not Optionals, for Failures

When an operation can fail and the caller needs to know why, throw an error. Use optionals only when the absence of a value is not an error (e.g., looking up a key in a dictionary).

```swift
// GOOD: Caller knows exactly what went wrong.
enum PersistenceError: Error, Sendable {
    case fileNotFound(path: String)
    case decodingFailed(underlying: Error)
    case encodingFailed(underlying: Error)
    case diskFull
}

func loadHighScores() throws(PersistenceError) -> [GameID: Int] {
    guard let data = try? Data(contentsOf: highScoresURL) else {
        throw .fileNotFound(path: highScoresURL.path)
    }
    do {
        return try JSONDecoder().decode([GameID: Int].self, from: data)
    } catch {
        throw .decodingFailed(underlying: error)
    }
}

// BAD: Caller has no idea what went wrong.
func loadHighScores() -> [GameID: Int]? {
    // Returns nil for file not found, decoding error, permission error...
    // The caller cannot distinguish these cases.
}
```

### Error Types

Define domain-specific error enums. Do not use `String`-based errors or generic `NSError`.

```swift
// GOOD: Typed, exhaustive, Sendable.
public enum AudioError: Error, Sendable {
    case engineInitializationFailed
    case fileNotFound(name: String)
    case bufferAllocationFailed
    case unsupportedFormat
}

// BAD: Stringly typed.
throw NSError(domain: "Audio", code: 1, userInfo: [NSLocalizedDescriptionKey: "Engine failed"])
```

### Error Handling in Effects

Effects that may fail should handle errors internally and convert them into Actions that the reducer can process:

```swift
// The effect catches errors and maps them to an action.
case .loadHighScores:
    return (state, .run {
        do {
            let scores = try await PersistenceActor.shared.loadHighScores()
            return .highScoresLoaded(scores)
        } catch {
            return .highScoresLoadFailed(error.localizedDescription)
        }
    })

// The reducer handles both success and failure actions.
case .highScoresLoaded(let scores):
    state.highScores = scores
    return (state, .none)

case .highScoresLoadFailed(let message):
    state.errorMessage = message
    return (state, .none)
```

### Never Silently Swallow Errors

If you catch an error, either handle it meaningfully or propagate it. Never write an empty catch block.

```swift
// BAD: Error silently swallowed. Bug will be invisible.
do {
    try engine.start()
} catch {
    // do nothing
}

// GOOD: Log and propagate meaningful information.
do {
    try engine.start()
} catch {
    logger.error("Haptic engine failed to start: \(error)")
    isSupported = false
}
```

### Assertions and Preconditions

Use `assert` for conditions that should be true during development but are non-fatal in production. Use `precondition` or `fatalError` only for truly unrecoverable situations.

```swift
// Assert: fires in debug, stripped in release. Use for invariant checks.
assert(gridSize.width > 0, "Grid width must be positive")

// Precondition: fires in debug AND release. Use for programmer errors.
precondition(index >= 0 && index < segments.count, "Segment index out of bounds")

// fatalError: use only when the app literally cannot continue.
guard let device = MTLCreateSystemDefaultDevice() else {
    fatalError("Metal is not supported on this device. The app requires Metal to render.")
}
```

---

## Testing Requirements

### What Must Be Tested

| Component | Required Tests | Coverage Target |
|-----------|---------------|----------------|
| Reducer | Every action with representative state combinations | 100% of action cases |
| Logic functions | All branches, edge cases, boundary conditions | 100% branch coverage |
| State types | Equatable conformance, initial state correctness | Sanity checks |
| C++ algorithms | Correctness, edge cases, performance | 100% branch coverage |
| Effects | Verify correct effect type is returned (not execution) | All effect-producing actions |
| Views | Snapshot tests for key states (optional but encouraged) | Key states |

### Reducer Testing Pattern

Test every action in isolation. Each test provides a specific state, sends one action, and asserts on the resulting state and effect type.

```swift
import XCTest
@testable import SnakePackage

final class SnakeReducerTests: XCTestCase {

    // MARK: - Start Game

    func testStartGameSetsPhaseToPlaying() {
        let state = SnakeState.initial(gridSize: GridSize(width: 20, height: 20))
        let (newState, _) = snakeReducer(state: state, action: .startGame)
        XCTAssertEqual(newState.phase, .playing)
    }

    func testStartGameResetsScore() {
        var state = SnakeState.initial(gridSize: GridSize(width: 20, height: 20))
        state.score = 42
        let (newState, _) = snakeReducer(state: state, action: .startGame)
        XCTAssertEqual(newState.score, 0)
    }

    func testStartGameReturnsTimerEffect() {
        let state = SnakeState.initial(gridSize: GridSize(width: 20, height: 20))
        let (_, effect) = snakeReducer(state: state, action: .startGame)
        // Assert that the effect is a .run (timer), not .none.
        if case .run = effect {
            // Expected
        } else {
            XCTFail("Expected .run effect for timer, got \(effect)")
        }
    }

    // MARK: - Change Direction

    func testChangeDirectionUpdatesDirection() {
        var state = SnakeState.initial(gridSize: GridSize(width: 20, height: 20))
        state.direction = .right
        state.phase = .playing
        let (newState, _) = snakeReducer(state: state, action: .changeDirection(.up))
        XCTAssertEqual(newState.direction, .up)
    }

    func testChangeDirectionIgnoresReversal() {
        var state = SnakeState.initial(gridSize: GridSize(width: 20, height: 20))
        state.direction = .right
        state.phase = .playing
        let (newState, _) = snakeReducer(state: state, action: .changeDirection(.left))
        XCTAssertEqual(newState.direction, .right, "Should not allow 180-degree reversal")
    }

    // MARK: - Tick

    func testTickAdvancesSnake() {
        var state = SnakeState.initial(gridSize: GridSize(width: 20, height: 20))
        state.snake = Snake(segments: [Position(x: 5, y: 5), Position(x: 4, y: 5)])
        state.direction = .right
        state.phase = .playing
        state.food = Food(position: Position(x: 19, y: 19), points: 10) // far away

        let (newState, _) = snakeReducer(state: state, action: .tick)

        XCTAssertEqual(newState.snake.head, Position(x: 6, y: 5))
    }

    func testTickDetectsWallCollision() {
        var state = SnakeState.initial(gridSize: GridSize(width: 10, height: 10))
        state.snake = Snake(segments: [Position(x: 9, y: 5), Position(x: 8, y: 5)])
        state.direction = .right
        state.phase = .playing

        let (newState, _) = snakeReducer(state: state, action: .tick)

        XCTAssertEqual(newState.phase, .gameOver)
    }

    func testTickIgnoredWhenPaused() {
        var state = SnakeState.initial(gridSize: GridSize(width: 20, height: 20))
        state.phase = .paused
        let originalSnake = state.snake

        let (newState, effect) = snakeReducer(state: state, action: .tick)

        XCTAssertEqual(newState.snake, originalSnake, "Snake should not move when paused")
        if case .none = effect {
            // Expected
        } else {
            XCTFail("Expected .none effect when paused")
        }
    }
}
```

### Logic Function Testing Pattern

Test pure logic functions independently from the reducer:

```swift
final class SnakeLogicTests: XCTestCase {

    func testAdvanceMovesSingleSegmentSnake() {
        let snake = Snake(segments: [Position(x: 5, y: 5)])
        let grid = GridSize(width: 10, height: 10)

        let result = SnakeLogic.advance(snake: snake, direction: .right, gridSize: grid)

        guard case .moved(let newSnake) = result else {
            XCTFail("Expected successful move")
            return
        }
        XCTAssertEqual(newSnake.head, Position(x: 6, y: 5))
        XCTAssertEqual(newSnake.segments.count, 1)
    }

    func testAdvanceDetectsSelfCollision() {
        // Snake shaped like: right, down, left -- head would collide with body if moving down.
        let snake = Snake(segments: [
            Position(x: 5, y: 5),  // head
            Position(x: 6, y: 5),
            Position(x: 6, y: 6),
            Position(x: 5, y: 6),
        ])
        let grid = GridSize(width: 10, height: 10)

        let result = SnakeLogic.advance(snake: snake, direction: .down, gridSize: grid)

        guard case .collision = result else {
            XCTFail("Expected collision with self")
            return
        }
    }

    func testGrowIncreasesLength() {
        let snake = Snake(segments: [
            Position(x: 5, y: 5),
            Position(x: 4, y: 5),
        ])

        let grown = SnakeLogic.grow(snake: snake)

        XCTAssertEqual(grown.segments.count, 3)
    }
}
```

### Effect Testing

Test that the reducer returns the correct effect type, not the effect's execution. Effects are opaque closures; testing their side effects belongs in integration tests.

```swift
/// Helper to classify effects for testing.
enum EffectKind {
    case none
    case run
    case fireAndForget
    case batch(count: Int)
}

func classify<A>(_ effect: Effect<A>) -> EffectKind {
    switch effect {
    case .none: return .none
    case .run: return .run
    case .fireAndForget: return .fireAndForget
    case .batch(let effects): return .batch(count: effects.count)
    }
}

func testEatingFoodProducesBatchEffect() {
    var state = /* state where snake head is adjacent to food */
    state.phase = .playing

    let (_, effect) = snakeReducer(state: state, action: .tick)

    if case .batch(let count) = classify(effect) {
        XCTAssertGreaterThanOrEqual(count, 2, "Should have audio, haptic, and timer effects")
    } else {
        XCTFail("Expected batch effect when eating food")
    }
}
```

### C++ Testing

C++ code is tested using C++ test frameworks or via Swift tests through CppCoreSwift:

```swift
// Testing C++ collision detection through the Swift overlay.
final class CollisionTests: XCTestCase {

    func testAABBContainsPoint() {
        let box = AABB(
            min: Vector2(x: 0, y: 0),
            max: Vector2(x: 10, y: 10)
        )

        XCTAssertTrue(box.contains(Vector2(x: 5, y: 5)))
        XCTAssertTrue(box.contains(Vector2(x: 0, y: 0)))   // edge
        XCTAssertTrue(box.contains(Vector2(x: 10, y: 10)))  // edge
        XCTAssertFalse(box.contains(Vector2(x: 11, y: 5)))
        XCTAssertFalse(box.contains(Vector2(x: -1, y: 5)))
    }

    func testBFSPathFindsShortestPath() {
        // 5x5 grid, no obstacles
        let path = GridAlgorithms.bfsPath(
            width: 5,
            height: 5,
            from: GridPosition(x: 0, y: 0),
            to: GridPosition(x: 4, y: 4),
            blocked: Array(repeating: false, count: 25)
        )

        // Manhattan distance is 8, so shortest path has 9 positions (including start and end).
        XCTAssertEqual(path.count, 9)
        XCTAssertEqual(path.first, GridPosition(x: 0, y: 0))
        XCTAssertEqual(path.last, GridPosition(x: 4, y: 4))
    }

    func testBFSPathReturnsEmptyWhenBlocked() {
        // 3x3 grid with middle row completely blocked.
        var blocked = Array(repeating: false, count: 9)
        blocked[3] = true  // (0,1)
        blocked[4] = true  // (1,1)
        blocked[5] = true  // (2,1)

        let path = GridAlgorithms.bfsPath(
            width: 3,
            height: 3,
            from: GridPosition(x: 0, y: 0),
            to: GridPosition(x: 2, y: 2),
            blocked: blocked
        )

        XCTAssertTrue(path.isEmpty, "Should return empty when path is blocked")
    }
}
```

### Test Naming Convention

Test method names follow the pattern: `test{MethodOrAction}{Scenario}{ExpectedBehavior}`.

```swift
func testAdvanceMovesSingleSegmentSnake() { ... }
func testTickDetectsWallCollision() { ... }
func testChangeDirectionIgnoresReversal() { ... }
func testStartGameResetsScore() { ... }
func testBFSPathReturnsEmptyWhenBlocked() { ... }
```

### Running Tests

All tests must pass before any merge to the main branch. The CI pipeline runs:

```bash
# Run all Swift package tests.
swift test --parallel

# Run C++ tests (if using a C++ test framework).
cd Packages/CppCore && cmake --build build && ctest --test-dir build
```

### Test Organization

- Test files mirror the structure of the source they test.
- One test file per source file (e.g., `SnakeReducer.swift` has `SnakeReducerTests.swift`).
- Test files live in the `Tests/` directory of their package.
- Use `// MARK: -` comments to group tests by action or scenario within a test file.
