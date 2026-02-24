[English](CodingStandards.md) | [简体中文](CodingStandards.zh-Hans.md)

# Coding Standards

## Table of Contents

1. [文件与模块组织](#file-and-module-organization)
2. [类型声明规则](#type-declaration-rules)
3. [纯函数与 Effect 类型](#pure-functions-and-the-effect-type)
4. [Actor 隔离与共享可变状态](#actor-isolation-and-shared-mutable-state)
5. [Swift 6 严格并发](#swift-6-strict-concurrency)
6. [可选项与安全](#optionals-and-safety)
7. [游戏模板结构](#game-template-structure)
8. [命名规范](#naming-conventions)
9. [依赖政策](#dependency-policy)
10. [C++ 代码标准](#c-code-standards)
11. [SwiftLint 规则](#swiftlint-rules)
12. [错误处理](#error-handling)
13. [测试要求](#testing-requirements)

---

## File and Module Organization

### One File, One Responsibility

每个源文件都有且只有一个主要职责。文件的长度应足以在不进行大量滚动的情况下完整理解。如果文件超过约 200 行，请考虑是否可以拆分。

```
推荐:
  SnakeState.swift          -- 定义 SnakeState 结构体
  SnakeAction.swift         -- 定义 SnakeAction 枚举
  SnakeReducer.swift        -- 定义 snakeReducer 函数
  SnakeLogic.swift          -- 为蛇的移动定义纯助手函数
  FoodSpawner.swift         -- 定义食物生成逻辑

不推荐:
  SnakeGame.swift           -- 在一个文件中包含状态、动作、reducer 和逻辑
  Helpers.swift             -- 各种不相关工具函数的集合
  Models.swift              -- 一个文件中包含多个不相关的类型
```

### Package = Module = Bounded Context

每个 Swift 包对应一个具有清晰边界的概念模块。包暴露最小限度的公共 API，并将实现细节设为 `internal` 或 `private`。

```
Packages/
  CoreEngine/              -- 共享的架构原语
  CppCore/                 -- C++ 算法
  CppCoreSwift/            -- CppCore 的 Swift 封装层
  SnakePackage/            -- 与贪吃蛇游戏相关的所有内容
  TetrisPackage/           -- 与俄罗斯方块相关的所有内容
  MinesweeperPackage/      -- 与扫雷相关的所有内容
```

### Import Discipline

- 仅导入所需内容。只使用 CoreEngine 类型时，优先使用 `import CoreEngine` 而非 `import Foundation`。
- 永远不要使用 `@_exported import`。每个文件必须显式导入其依赖项。
- 按字母顺序对导入进行排序：首先是 Apple 框架，然后是项目包。

```swift
import CoreEngine
import SwiftUI

// 不要使用:
import SwiftUI
import Foundation   // 如果 CoreEngine 已经重新导出了你需要的内容，则不需要此项
import CoreEngine
```

---

## Type Declaration Rules

### Every Public Type Gets Its Own File

如果一个类型是 `public` 的，它必须是该文件中唯一的首要声明，并且文件名必须与类型名一致。

```
Public struct SnakeState   -> SnakeState.swift
Public enum SnakeAction    -> SnakeAction.swift
Public protocol RenderPipeline -> RenderPipeline.swift
Public actor AudioActor    -> AudioActor.swift
```

小型的私有助手类型可以与它们支持的公共类型定义在同一个文件中，但前提是它们紧密耦合且在其他地方无用。

```swift
// SnakeState.swift

/// 贪吃蛇游戏会话的完整状态。
public struct SnakeState: Sendable, Equatable {
    public var snake: Snake
    public var food: Food
    public var score: Int
    public var phase: GamePhase
    public var direction: Direction
    public var gridSize: GridSize
    public var speed: Speed
}

// 这个私有助手与 SnakeState 紧密耦合，且不在其他地方使用。
private extension SnakeState {
    var isAlive: Bool { phase == .playing }
}
```

### Struct by Default

除非有特定理由使用其他类型，否则请使用 `struct`：

| 类型 | 使用场景 |
|------|-------------|
| `struct` | 默认。所有状态类型、配置、值对象。 |
| `enum` | 封闭的情况集合：动作、渲染命令、阶段。 |
| `actor` | 必须线程安全的共享可变状态。 |
| `class` | 仅当框架 API 要求时（例如 `UIViewController` 子类）。 |
| `protocol` | 当存在一个接口的多种实现时（例如 `RenderPipeline`）。 |

永远不要为模型类型使用 `class`。永远不要为状态使用 `class`。如果你认为需要引用语义，请使用 actor。

---

## Pure Functions and the Effect Type

### Pure Functions Preferred

纯函数仅依赖于其参数，并仅通过返回值产生输出。它不读写全局状态，不执行 I/O，也不触发副作用。

所有游戏逻辑函数必须是纯函数：

```swift
// 推荐：纯函数。易于测试，易于理解。
func advance(snake: Snake, direction: Direction, gridSize: GridSize) -> MoveResult {
    let newHead = snake.head.moved(in: direction)
    guard gridSize.contains(newHead) else { return .collision }
    guard !snake.body.contains(newHead) else { return .collision }
    return .moved(Snake(segments: [newHead] + snake.segments.dropLast()))
}

// 不推荐：读写共享可变状态。无法孤立测试。
func advance() {
    let newHead = gameState.snake.head.moved(in: gameState.direction)
    if gameState.gridSize.contains(newHead) {
        gameState.snake = Snake(segments: [newHead] + gameState.snake.segments.dropLast())
    } else {
        gameState.phase = .gameOver
        audioPlayer.play("gameover.wav")  // 副作用！
    }
}
```

### Side Effects Through the Effect Type Only

当游戏逻辑需要与外部世界交互（播放音频、触发触觉反馈、设置定时器、持久化数据）时，必须从 reducer 返回一个 `Effect` 值。reducer 本身从不执行副作用。

```swift
// 推荐：副作用被声明为一个值，由 StateStore 执行。
case .scorePoint:
    state.score += 1
    return (state, .batch([
        .fireAndForget { await AudioActor.shared.play(.point) },
        .fireAndForget { await HapticActor.shared.trigger(.light) }
    ]))

// 不推荐：在 reducer 中直接执行副作用。
case .scorePoint:
    state.score += 1
    AudioActor.shared.play(.point)  // 错误：reducer 中的副作用
    return (state, .none)
```

### Effect Composition

为常用模式构建可重用的 effect 助手：

```swift
/// 同时播放声音并触发触觉反馈。
func feedback<A: Sendable>(
    sound: SoundEffect,
    haptic: HapticPattern
) -> Effect<A> {
    .batch([
        .fireAndForget { await AudioActor.shared.play(sound) },
        .fireAndForget { await HapticActor.shared.trigger(haptic) }
    ])
}

/// 在延迟后调度下一个游戏刻。
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

如果一段可变状态从多个并发域访问，它必须是一个 `actor`。没有例外。不使用带锁的类。不使用基于 `DispatchQueue` 的同步。不使用 `@unchecked Sendable`。

```swift
// 推荐：在 actor 中的共享可变状态。
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

// 不推荐：在带有锁的类中的共享可变状态。
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

每个 actor 应该管理一段内聚的状态：

| Actor | 职责 |
|-------|---------------|
| `StateStore` | 游戏会话状态和 reduce 循环 |
| `GameLoop` | 刻时记时和循环控制 |
| `AudioActor` | 音频引擎、缓冲区、播放 |
| `HapticActor` | 触觉引擎和模式 |
| `ScoreStore` | 最高分持久化 |
| `SettingsStore` | 用户偏好设置 |

不要将不相关的状态合并到单个 actor 中。“上帝 actor”与“上帝对象”一样糟糕。

### Avoiding Actor Reentrancy Issues

请注意，actor 方法内部的 `await` 是一个挂起点，其他调用可能会交替执行。将 actor 方法设计得简短，并尽可能避免多个挂起点。

```swift
// 注意：有两个挂起点。状态可能在它们之间发生变化。
public func processAndSave(action: Action) async {
    let result = await heavyComputation(action)  // 挂点 1
    await persistenceActor.save(result)           // 挂点 2
    // 此时，self.state 可能已被另一个调用修改。
}

// 更好：尽量减少挂起点。同步执行本地工作。
public func processAndSave(action: Action) {
    let result = computeLocally(action)  // 同步，无挂起
    Task {
        await persistenceActor.save(result)  // 即发即弃
    }
}
```

---

## Swift 6 Strict Concurrency

### All Types Must Be Sendable

每个跨越隔离边界的类型都必须符合 `Sendable`。在 Swift 6 严格并发模式下（所有包均已启用），编译器会强制执行此规则。

```swift
// 推荐：值类型自动符合 Sendable。
public struct SnakeState: Sendable, Equatable {
    public var snake: Snake
    public var food: Food
    public var score: Int
}

// 推荐：具有 Sendable 关联值的枚举符合 Sendable。
public enum SnakeAction: Sendable {
    case tick
    case changeDirection(Direction)
    case startGame
    case pauseGame
}

// 推荐：Actor 本质上符合 Sendable。
public actor AudioActor: Sendable { ... }

// 不推荐：类不符合 Sendable。请使用结构体或 actor。
public class GameState {
    var score: Int = 0  // 可变引用类型 = 不符合 Sendable
}
```

### Strict Concurrency Compiler Settings

每个 `Package.swift` 必须启用严格并发检查：

```swift
swiftSettings: [
    .swiftLanguageMode(.v6)
]
```

### No @unchecked Sendable

永远不要使用 `@unchecked Sendable` 来消除编译器警告。如果编译器提示某个类型不是 Sendable，请修正该类型，不要压制警告。唯一的允许例外是包装已知线程安全但缺乏 Sendable 符合性的框架类型（例如某些 Core Foundation 类型），即便如此，也必须添加注释说明其安全的原因。

### Global State

禁止全局可变状态。全局 `let` 常量是可以的，因为它们是不可变的。

```swift
// 推荐：不可变的全局常量。
public let maxGridSize = GridSize(width: 30, height: 30)

// 推荐：用于共享可变状态的 Actor 单例。
public actor AudioActor {
    public static let shared = AudioActor()
}

// 不推荐：可变的全局变量。
public var currentScore = 0  // 随时可能发生数据竞争
```

---

## Optionals and Safety

### No Force Unwraps

所有生产代码中禁止强制解包 (`!`)。每个可选项都必须安全地解包。

```swift
// 推荐
guard let device = MTLCreateSystemDefaultDevice() else {
    fatalError("此设备不支持 Metal")
    // 这里使用 fatalError 是可以接受的，因为没有 Metal 应用根本无法运行。
}

if let highScore = scores[gameID] {
    displayScore(highScore)
}

let name = player.name ?? "Unknown"

// 不推荐
let device = MTLCreateSystemDefaultDevice()!
let highScore = scores[gameID]!
```

唯一的例外是带有描述性消息的 `fatalError`，用于真正不可能发生的状态（例如启动时所需的系统资源不可用）。这比强制解包更好，因为它提供了清晰的错误消息。

### No Implicitly Unwrapped Optionals

禁止隐式解包可选项 (`Type!`)。它们的存在是为了支持应避免使用的二阶段初始化模式。

```swift
// 不推荐
var engine: CHHapticEngine!

// 推荐：使用真正的可选项并处理 nil 情况。
var engine: CHHapticEngine?

// 推荐：或者在声明时初始化。
let engine: CHHapticEngine = try CHHapticEngine()

// 推荐：或者使用延迟初始化。
lazy var engine: CHHapticEngine = {
    try! CHHapticEngine()  // 仅在 lazy 变量中允许，此时失败 = 程序员错误
}()
```

### Optional Chaining Preferred

访问嵌套可选项时，使用可选链而非嵌套的 `if let`：

```swift
// 推荐
let score = gameSession?.state.score ?? 0

// 冗长（对于简单访问可以接受但不推荐）
if let session = gameSession {
    let score = session.state.score
    displayScore(score)
}
```

---

## Game Template Structure

每个游戏包都遵循标准的目录结构。这种一致性使得即使之前不熟悉，也能轻松导航任何游戏包。

```
Packages/
  SnakePackage/
    Sources/
      SnakePackage/
        State/
          SnakeState.swift          -- 完整的游戏状态结构体
          Snake.swift               -- 蛇的值类型（段、头、身）
          Food.swift                -- 食物值类型（位置、分数、类型）
          GridSize.swift            -- 网格尺寸
          Speed.swift               -- 刻间隔配置
          GamePhase.swift           -- 枚举：菜单、进行中、已暂停、游戏结束
        Action/
          SnakeAction.swift         -- 游戏可以处理的所有动作
        Reducer/
          SnakeReducer.swift        -- reduce 函数
        Logic/
          SnakeLogic.swift          -- 蛇移动的纯函数
          FoodSpawner.swift         -- 食物放置的纯函数
          CollisionDetection.swift  -- 碰撞检查的纯函数
          ScoreCalculator.swift     -- 分数计算的纯函数
        View/
          SnakeGameView.swift       -- 主 SwiftUI 游戏视图
          SnakeGridView.swift       -- 网格渲染子视图
          SnakeOverlayView.swift    -- 暂停/游戏结束覆盖层
          SnakeMenuView.swift       -- 游戏前菜单
        Configuration/
          SnakeConfiguration.swift  -- 难度、网格尺寸、速度预设
          SnakeAssets.swift         -- 资源目录引用
          SnakeColors.swift         -- 配色方案
    Tests/
      SnakePackageTests/
        SnakeReducerTests.swift     -- 每个动作/状态转换的测试
        SnakeLogicTests.swift       -- 移动和碰撞逻辑的测试
        FoodSpawnerTests.swift      -- 食物放置的测试
        ScoreCalculatorTests.swift  -- 分数计算的测试
```

### Directory Responsibilities

| 目录 | 内容 | 规则 |
|-----------|----------|-------|
| `State/` | 构成游戏状态的所有值类型。 | 所有类型必须符合 `Sendable` 和 `Equatable`。无逻辑，仅包含数据。 |
| `Action/` | 动作枚举及相关类型。 | 一个包含所有可能动作的枚举。必须符合 `Sendable`。 |
| `Reducer/` | reduce 函数。 | 有且仅有一个公共函数。必须是纯函数。 |
| `Logic/` | 由 reducer 调用的纯助手函数。 | 禁止导入 UIKit、SwiftUI 或渲染框架。所有函数均为自由函数或静态方法。 |
| `View/` | 游戏的 SwiftUI 视图。 | 视图观察状态并分发动作。视图中禁止包含游戏逻辑。 |
| `Configuration/` | 常量、预设、资源引用。 | 所有值均为 `let` 常量或静态属性。 |

### State Directory Rules

- 状态结构体中的每个属性必须是值类型。
- 状态结构体必须符合 `Sendable` 和 `Equatable`。
- 派生属性（从其他状态计算得出）应该是计算属性，而不是存储属性。
- 状态中不使用可选项，除非缺少值具有语义意义（例如，`var activePowerUp: PowerUp?` 是可以的；`var score: Int?` 不行 —— 应使用 `var score: Int = 0`）。

### Logic Directory Rules

- 无副作用。每个函数都是纯函数。
- 禁止导入 Apple UI 框架。
- 函数应作为命名空间枚举上的 `static` 方法或自由函数。
- 函数通过参数接收所有需要的数据，从不访问全局状态。

```swift
// 推荐：纯粹、可测试，将所有输入作为参数。
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

| 元素 | 规范 | 示例 |
|---------|-----------|---------|
| 类型 (struct, enum, actor, class, protocol) | 大驼峰 (PascalCase) | `SnakeState`, `GamePhase`, `RenderPipeline` |
| 函数和方法 | 小驼峰 (camelCase) | `advance(snake:direction:)`, `renderCommands(from:)` |
| 变量和属性 | 小驼峰 (camelCase) | `currentScore`, `gridSize`, `isAlive` |
| 常量 (let) | 小驼峰 (camelCase) | `maxGridWidth`, `defaultTickInterval` |
| 枚举成员 | 小驼峰 (camelCase) | `.playing`, `.gameOver`, `.changeDirection` |
| 布尔属性 | 读起来像个问题 | `isAlive`, `hasFood`, `canMove`, `shouldRender` |
| 类型参数 | 单个大写字母或大驼峰 | `<State>`, `<Action>`, `<T>` |
| 文件名 | 匹配主要类型 | `SnakeState.swift`, `GameLoop.swift` |

### Specific Naming Patterns

**状态类型**: `{Game}State` —— 例如 `SnakeState`, `TetrisState`, `MinesweeperState`。

**动作类型**: `{Game}Action` —— 例如 `SnakeAction`, `TetrisAction`。

**Reducer 函数**: `{game}Reducer` (小驼峰) —— 例如 `snakeReducer`, `tetrisReducer`。

**逻辑命名空间**: `{Game}Logic` —— 例如 `SnakeLogic`, `TetrisLogic`。

**视图类型**: `{Game}{Purpose}View` —— 例如 `SnakeGameView`, `SnakeGridView`, `TetrisMenuView`。

**配置类型**: `{Game}Configuration` —— 例如 `SnakeConfiguration`。

### Abbreviation Policy

- 不要在公共 API 中缩写单词。使用 `position` 而非 `pos`，`direction` 而非 `dir`，`configuration` 而非 `config`。
- 允许使用标准的 Apple 缩写：`URL`, `ID`, `RGB`, `AABB`。
- 仅允许在以下情况使用单字母变量名：循环索引 (`i`, `j`)、具有明显上下文的闭包 (`$0`) 以及泛型类型参数 (`T`)。

```swift
// 推荐
let gridPosition = Position(x: 5, y: 10)
let moveDirection: Direction = .up
let tickInterval: Duration = .milliseconds(100)

// 不推荐
let gridPos = Position(x: 5, y: 10)
let moveDir: Direction = .up
let tickInt: Duration = .milliseconds(100)
```

### Argument Labels

遵循 Swift API 设计指南。方法名在调用处读起来应像英语短语：

```swift
// 推荐：读起来很自然。
snake.moved(in: .up)
grid.contains(position)
FoodSpawner.spawn(avoiding: occupiedPositions, in: gridSize)

// 不推荐：冗余或不清晰的标签。
snake.move(direction: .up)
grid.containsPosition(position)
FoodSpawner.spawnFood(avoidingPositions: occupiedPositions, inGrid: gridSize)
```

---

## Dependency Policy

### No Third-Party Dependencies

本项目不使用任何第三方 Swift 包。每个依赖项要么是：

1. Apple 框架（SwiftUI, Metal, SpriteKit, AVFoundation, CoreHaptics, GameController）。
2. 本仓库内的内部包（CoreEngine, CppCore, CppCoreSwift, 游戏包）。

### Rationale

- **稳定性** —— 无依赖项被弃用、引入破坏性更改或被恶意篡改的风险。
- **构建时间** —— 无需依赖解析，无需下载，无版本冲突。
- **理解度** —— 每一行代码都由团队编写并由团队理解。
- **二进制大小** —— 二进制文件中不会包含大型框架中未使用的代码。
- **离线开发** —— 项目在没有互联网连接的情况下也能构建。

### What This Means in Practice

- 需要 JSON 编码？使用 `Codable` (Foundation)。
- 需要网络？使用 `URLSession` (Foundation)。
- 需要测试断言库？使用带有自定义助手的 `XCTest`。
- 需要依赖注入？使用基于协议的注入；不使用容器框架。
- 需要响应式状态观察？使用 `AsyncStream` 和 `@Observable`。
- 需要图像加载？使用 `UIImage` / `NSImage` (UIKit/AppKit)。

如果某项任务似乎需要第三方库，请重新考虑方法。使用 Apple 框架的解决方案可能比预期的更简单。

---

## C++ Code Standards

### File Organization

- 头文件放在 `include/cppcore/` 中，后缀为 `.hpp`。
- 实现文件（如果有）放在 `src/` 中，后缀为 `.cpp`。
- 简单的算法优先使用 header-only 实现。

### Naming Conventions

| 元素 | 规范 | 示例 |
|---------|-----------|---------|
| 函数 | 蛇形命名 (snake_case) | `bfs_path`, `aabb_circle_intersect` |
| 类型 (struct, class) | 大驼峰 (PascalCase) | `Vec2`, `AABB`, `GridPos` |
| 命名空间 | 小写单词 | `cppcore` |
| 成员变量 | 蛇形命名 (snake_case) | `grid_width`, `max_depth` |
| 常量 / 宏 | 全大写蛇形 (UPPER_SNAKE_CASE) | `MAX_GRID_SIZE`, `PI` |
| 模板参数 | 大驼峰 (PascalCase) | `<typename T>`, `<typename Comparator>` |
| 文件名 | 蛇形命名 (snake_case) | `vec2.hpp`, `collision.hpp`, `grid.hpp` |

### Namespace

所有 C++ 代码都位于 `cppcore` 命名空间中。全局范围内不应有代码。

```cpp
// 推荐
namespace cppcore {
    struct Vec2 { float x; float y; };
}

// 不推荐：污染全局命名空间。
struct Vec2 { float x; float y; };
```

### Modern C++ Practices

- 使用 C++17 或更高版本。
- 简单数据类型优先使用具有公共成员的 `struct`。
- 尽可能在所有地方使用 `const`：`const` 参数、`const` 成员函数、`const` 本地变量。
- 不使用原始的 `new`/`delete`。使用栈分配或标准容器。
- 不使用 C 风格的类型转换。使用 `static_cast`、`reinterpret_cast`（慎用）或构造函数语法。
- 使用 `#pragma once` 代替 include guard。
- 使用标准库中的 `std::vector`, `std::array`, `std::optional`, `std::string_view`。
- 不使用异常。可能失败的函数返回 `std::optional` 或使用输出参数。

```cpp
// 推荐
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

- 保持 C++ 类型简单。Swift 互操作最适合具有公共成员和简单构造函数的结构体。
- 避免难以桥接的 C++ 特性：模板（除非在实现细节中）、多重继承、算术以外的运算符重载。
- 将从 Swift 使用的每个类型都必须在模块映射（module map）包含的公共头文件中定义。

---

## SwiftLint Rules

项目使用 SwiftLint 来强制执行基本的风格一致性。以下规则已启用并在 CI 中强制执行。

### Enforced Rules

| 规则 | 描述 | 示例（违规） |
|------|-------------|-------------------|
| `force_unwrapping` | 禁止强制解包 (`!`) | `let x = optional!` |
| `implicitly_unwrapped_optional` | 禁止 `Type!` 声明 | `var x: String!` |
| `force_cast` | 禁止 `as!` 强制转换 | `let x = y as! Int` |
| `line_length` | 每行最多 120 个字符 | (长行) |
| `file_length` | 每个文件最多 400 行 | (长文件) |
| `function_body_length` | 每个函数体最多 50 行 | (长函数) |
| `type_body_length` | 每个类型体最多 300 行 | (长类型声明) |
| `cyclomatic_complexity` | 每个函数圈复杂度最多 10 | (深度嵌套的逻辑) |
| `nesting` | 类型嵌套最多 2 层 | (结构体里的结构体里的结构体) |
| `identifier_name` | 最小 3 字符，最大 50 字符 | `let x = 5` (太短，除非是循环索引) |
| `trailing_whitespace` | 无行尾空格 | (行尾的不可见字符) |
| `vertical_whitespace` | 最多连续 1 个空行 | (多个连续空行) |
| `trailing_comma` | 多行集合中使用尾随逗号 | `[1, 2, 3]` (无尾随逗号) |
| `unused_import` | 禁止未使用的导入 | `import Foundation` (当未用到任何 Foundation 内容时) |
| `redundant_optional_initialization` | 不要写 `var x: Int? = nil` | `var x: Int? = nil` |
| `empty_count` | 使用 `.isEmpty` 而非 `.count == 0` | `array.count == 0` |
| `first_where` | 使用 `.first(where:)` 而非 `.filter().first` | `array.filter { $0 > 5 }.first` |
| `sorted_first_last` | 使用 `.min()` / `.max()` 而非 `.sorted().first` / `.sorted().last` | `array.sorted().first` |

### SwiftLint Configuration Excerpt

```yaml
# .swiftlint.yml

disabled_rules:
  - todo  # 开发过程中允许使用 TODO 注释

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

当操作可能失败且调用者需要知道原因时，请抛出错误。仅当缺少值不代表错误时才使用可选项（例如，在字典中查找键）。

```swift
// 推荐：调用者确切知道出了什么问题。
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

// 不推荐：调用者不知道哪里出了问题。
func loadHighScores() -> [GameID: Int]? {
    // 对于文件未找到、解码错误、权限错误都返回 nil...
    // 调用者无法区分这些情况。
}
```

### Error Types

定义领域特定的错误枚举。不要使用基于 `String` 的错误或通用的 `NSError`。

```swift
// 推荐：类型化、详尽、Sendable。
public enum AudioError: Error, Sendable {
    case engineInitializationFailed
    case fileNotFound(name: String)
    case bufferAllocationFailed
    case unsupportedFormat
}

// 不推荐：强行使用字符串。
throw NSError(domain: "Audio", code: 1, userInfo: [NSLocalizedDescriptionKey: "引擎故障"])
```

### Error Handling in Effects

可能失败的 Effect 应该在内部处理错误，并将其转换为 Reducer 可以处理的 Action：

```swift
// Effect 捕获错误并将其映射到 action。
case .loadHighScores:
    return (state, .run {
        do {
            let scores = try await PersistenceActor.shared.loadHighScores()
            return .highScoresLoaded(scores)
        } catch {
            return .highScoresLoadFailed(error.localizedDescription)
        }
    })

// Reducer 处理成功和失败两种 action。
case .highScoresLoaded(let scores):
    state.highScores = scores
    return (state, .none)

case .highScoresLoadFailed(let message):
    state.errorMessage = message
    return (state, .none)
```

### Never Silently Swallow Errors

如果捕获了错误，要么进行有意义的处理，要么将其传播。永远不要编写空的 catch 块。

```swift
// 不推荐：错误被默默吞掉。Bug 将变得不可见。
do {
    try engine.start()
} catch {
    // 什么都不做
}

// 推荐：记录并传播有意义的信息。
do {
    try engine.start()
} catch {
    logger.error("触觉引擎启动失败: \(error)")
    isSupported = false
}
```

### Assertions and Preconditions

使用 `assert` 检查在开发期间应为真但在生产环境中非致命的条件。仅在真正无法恢复的情况下使用 `precondition` 或 `fatalError`。

```swift
// Assert：在调试模式下触发，在发布模式下剔除。用于不变性检查。
assert(gridSize.width > 0, "网格宽度必须为正数")

// Precondition：在调试和发布模式下都会触发。用于程序员错误。
precondition(index >= 0 && index < segments.count, "段索引越界")

// fatalError：仅在应用确实无法继续运行时使用。
guard let device = MTLCreateSystemDefaultDevice() else {
    fatalError("此设备不支持 Metal。应用需要 Metal 来进行渲染。")
}
```

---

## Testing Requirements

### What Must Be Tested

| 组件 | 要求的测试 | 覆盖率目标 |
|-----------|---------------|----------------|
| Reducer | 具有代表性的状态组合下的每个动作 | 100% 的动作分支 |
| Logic 函数 | 所有分支、边缘情况、边界条件 | 100% 的分支覆盖率 |
| 状态类型 | Equatable 符合性、初始状态正确性 | 健全性检查 |
| C++ 算法 | 正确性、边缘情况、性能 | 100% 的分支覆盖率 |
| Effects | 验证返回了正确的 effect 类型（而非执行过程） | 所有产生 effect 的动作 |
| 视图 | 关键状态的快照测试（可选但鼓励） | 关键状态 |

### Reducer Testing Pattern

孤立地测试每个动作。每个测试提供一个特定状态，发送一个动作，并对产生的状态和 effect 类型进行断言。

```swift
import XCTest
@testable import SnakePackage

final class SnakeReducerTests: XCTestCase {

    // MARK: - 开始游戏

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
        // 断言该 effect 是 .run (定时器)，而不是 .none。
        if case .run = effect {
            // 符合预期
        } else {
            XCTFail("预期定时器为 .run effect，实际得到 \(effect)")
        }
    }

    // MARK: - 改变方向

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
        XCTAssertEqual(newState.direction, .right, "不应允许 180 度掉头")
    }

    // MARK: - 游戏刻 (Tick)

    func testTickAdvancesSnake() {
        var state = SnakeState.initial(gridSize: GridSize(width: 20, height: 20))
        state.snake = Snake(segments: [Position(x: 5, y: 5), Position(x: 4, y: 5)])
        state.direction = .right
        state.phase = .playing
        state.food = Food(position: Position(x: 19, y: 19), points: 10) // 离得很远

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

        XCTAssertEqual(newState.snake, originalSnake, "暂停时不应移动蛇")
        if case .none = effect {
            // 符合预期
        } else {
            XCTFail("暂停时预期为 .none effect")
        }
    }
}
```

### Logic Function Testing Pattern

独立于 reducer 测试纯逻辑函数：

```swift
final class SnakeLogicTests: XCTestCase {

    func testAdvanceMovesSingleSegmentSnake() {
        let snake = Snake(segments: [Position(x: 5, y: 5)])
        let grid = GridSize(width: 10, height: 10)

        let result = SnakeLogic.advance(snake: snake, direction: .right, gridSize: grid)

        guard case .moved(let newSnake) = result else {
            XCTFail("预期成功移动")
            return
        }
        XCTAssertEqual(newSnake.head, Position(x: 6, y: 5))
        XCTAssertEqual(newSnake.segments.count, 1)
    }

    func testAdvanceDetectsSelfCollision() {
        // 蛇的形状为：向右、向下、向左 —— 如果向下移动，头部会撞到身体。
        let snake = Snake(segments: [
            Position(x: 5, y: 5),  // 头
            Position(x: 6, y: 5),
            Position(x: 6, y: 6),
            Position(x: 5, y: 6),
        ])
        let grid = GridSize(width: 10, height: 10)

        let result = SnakeLogic.advance(snake: snake, direction: .down, gridSize: grid)

        guard case .collision = result else {
            XCTFail("预期发生自身碰撞")
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

测试 reducer 返回了正确的 effect 类型，而不是测试 effect 的执行。Effect 是不透明的闭包；测试其副作用属于集成测试。

```swift
/// 用于为测试对 effect 进行分类的助手。
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
    var state = /* 蛇头紧邻食物的状态 */
    state.phase = .playing

    let (_, effect) = snakeReducer(state: state, action: .tick)

    if case .batch(let count) = classify(effect) {
        XCTAssertGreaterThanOrEqual(count, 2, "应包含音频、触觉反馈和定时器 effect")
    } else {
        XCTFail("吃到食物时预期为 batch effect")
    }
}
```

### C++ Testing

C++ 代码使用 C++ 测试框架进行测试，或通过 CppCoreSwift 经由 Swift 测试：

```swift
// 通过 Swift 封装层测试 C++ 碰撞检测。
final class CollisionTests: XCTestCase {

    func testAABBContainsPoint() {
        let box = AABB(
            min: Vector2(x: 0, y: 0),
            max: Vector2(x: 10, y: 10)
        )

        XCTAssertTrue(box.contains(Vector2(x: 5, y: 5)))
        XCTAssertTrue(box.contains(Vector2(x: 0, y: 0)))   // 边缘
        XCTAssertTrue(box.contains(Vector2(x: 10, y: 10)))  // 边缘
        XCTAssertFalse(box.contains(Vector2(x: 11, y: 5)))
        XCTAssertFalse(box.contains(Vector2(x: -1, y: 5)))
    }

    func testBFSPathFindsShortestPath() {
        // 5x5 网格，无障碍物
        let path = GridAlgorithms.bfsPath(
            width: 5,
            height: 5,
            from: GridPosition(x: 0, y: 0),
            to: GridPosition(x: 4, y: 4),
            blocked: Array(repeating: false, count: 25)
        )

        // 曼哈顿距离为 8，因此最短路径有 9 个位置（包括起点和终点）。
        XCTAssertEqual(path.count, 9)
        XCTAssertEqual(path.first, GridPosition(x: 0, y: 0))
        XCTAssertEqual(path.last, GridPosition(x: 4, y: 4))
    }

    func testBFSPathReturnsEmptyWhenBlocked() {
        // 3x3 网格，中间一行完全阻塞。
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

        XCTAssertTrue(path.isEmpty, "路径被阻塞时应返回空")
    }
}
```

### Test Naming Convention

测试方法名遵循以下模式：`test{MethodOrAction}{Scenario}{ExpectedBehavior}`。

```swift
func testAdvanceMovesSingleSegmentSnake() { ... }
func testTickDetectsWallCollision() { ... }
func testChangeDirectionIgnoresReversal() { ... }
func testStartGameResetsScore() { ... }
func testBFSPathReturnsEmptyWhenBlocked() { ... }
```

### Running Tests

在合并到 main 分支之前，所有测试必须通过。CI 流水线运行：

```bash
# Run all Swift package tests.
swift test --parallel

# Run C++ tests (if using a C++ test framework).
cd Packages/CppCore && cmake --build build && ctest --test-dir build
```

### Test Organization

- 测试文件镜像了它们所测试的源码结构。
- 每个源文件对应一个测试文件（例如，`SnakeReducer.swift` 对应 `SnakeReducerTests.swift`）。
- 测试文件位于其对应包的 `Tests/` 目录中。
- 使用 `// MARK: -` 注释在测试文件中按动作或场景对测试进行分组。
