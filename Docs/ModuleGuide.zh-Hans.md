[English](ModuleGuide.md) | [简体中文](ModuleGuide.zh-Hans.md)

# Module Guide: Adding a New Game

本指南将引导你从零开始创建一个新的游戏模块，使用项目的 TCA 风格架构。每个游戏都是 `Packages/` 下一个独立的 Swift 软件包，并接入共享引擎。

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

- Xcode 26.0+ 以及 Swift 6.1
- 熟悉项目的单向数据流：
  ```
  User Input -> Action -> Reducer(State, Action) -> (NewState, Effect)
  ```
- 阅读现有的 `BlockPuzzle` 或 `SnakeGame` 软件包作为参考。

---

## Directory Structure

每个游戏模块都应遵循以下模板布局：

```
Packages/MyNewGame/
├── Package.swift
├── Sources/
│   └── MyNewGame/
│       ├── MyNewGame.swift              # GameDefinition 实现
│       ├── State/
│       │   └── MyNewGameState.swift     # 符合 GameState 协议的结构体
│       ├── Action/
│       │   └── MyNewGameAction.swift    # Action 枚举
│       ├── Reducer/
│       │   └── MyNewGameReducer.swift   # 纯 Reduce 函数
│       ├── Logic/
│       │   └── MyNewGameLogic.swift     # 辅助逻辑（碰撞、计分等）
│       ├── View/
│       │   ├── MyNewGameView.swift      # 根 SwiftUI 视图
│       │   └── MyNewGameBoardView.swift # 游戏面板渲染
│       └── Configuration/
│           └── MyNewGameConfig.swift    # 难度设置、常量
└── Tests/
    └── MyNewGameTests/
        ├── MyNewGameReducerTests.swift
        └── MyNewGameLogicTests.swift
```

对于较简单的游戏，你可以展平目录结构（如 `BlockPuzzle` 所示），但仍应保持概念上的分离。

---

## Step 1: Create the SPM Package

创建 `Packages/MyNewGame/Package.swift`：

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

关键点：
- 平台必须是 `.iOS(.v26)` 以匹配项目的其余部分。
- 始终依赖 `CoreEngine`（提供 `GameState`, `Reduce`, `Effect`, `StateStore` 等）。
- 始终依赖 `GameUI`（提供 `AppTheme`, `GlassCard`, `GlassButton` 等共享组件）。
- 如果你需要 C++ 算法（碰撞、寻路），请添加对 `CppCore` 的依赖。
- 如果你需要 Metal 渲染，请添加对 `MetalRenderer` 的依赖。

---

## Step 2: Define the State

创建一个符合 `CoreEngine` 中 `GameState` 协议的结构体。

`GameState` 协议要求三个属性：

```swift
public protocol GameState: Sendable, Equatable {
    var isRunning: Bool { get }
    var score: Int { get }
    var isGameOver: Bool { get }
}
```

示例实现：

```swift
import CoreEngine

public struct MyNewGameState: GameState, Equatable, Sendable {
    // GameState 要求的属性
    public var isRunning: Bool
    public var score: Int
    public var isGameOver: Bool

    // 游戏特定状态
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

指导原则：
- 状态必须是**值类型**（结构体）。
- 状态必须符合 `Sendable` 和 `Equatable`。
- 保持状态精简——只存储在任何时刻完整描述游戏所需的内容。
- 使用 `init()` 为新游戏设置合理的默认值。

---

## Step 3: Define Actions

创建一个枚举，列出所有可能的事件或用户交互。

```swift
import CoreEngine

public enum MyNewGameAction: Sendable {
    // 生命周期
    case start
    case pause
    case resume
    case reset

    // 游戏循环
    case tick(delta: Double)

    // 用户输入
    case tap(x: Float, y: Float)
    case swipe(direction: Direction)

    // 内部事件
    case spawnEnemy
    case scorePoint(Int)
}
```

指导原则：
- Action 必须符合 `Sendable`。
- Action 应该**描述发生了什么**，而不是应该发生什么。倾向于使用 `case userTappedPlay` 而不是 `case startTheGame`。
- 按类别对 Action 进行分组并添加注释。
- 关联值应该是值类型。

---

## Step 4: Write the Reducer

Reducer 是一个具有以下签名的纯函数：

```swift
public typealias Reduce<State: Sendable, Action: Sendable> =
    @Sendable (State, Action) -> (State, Effect<Action>)
```

它接收当前状态和一个 Action，并返回新状态以及任何副作用。

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
        // 向特定方向移动玩家
        return (newState, .none)

    case .spawnEnemy:
        // 向状态中添加敌人
        return (newState, .none)

    case .scorePoint(let points):
        newState.score += points
        return (newState, .none)
    }
}
```

指导原则：
- **纯函数**——Reducer 本身不产生副作用。所有副作用都通过 `Effect` 处理。
- 使用 `var newState = state` 拷贝状态，修改副本并返回。
- 不需要副作用时返回 `.none`。
- 对于产生后续 Action 的副作用，使用 `.run`：
  ```swift
  return (newState, .run {
      try await Task.sleep(for: .seconds(2.0))
      return .spawnEnemy
  })
  ```
- 对于“发后即忘”的副作用（声音、触觉），使用 `.fireAndForget`：
  ```swift
  return (newState, .fireAndForget {
      await AudioEngine.shared.play(.scoreUp)
  })
  ```

---

## Step 5: Implement Game Logic

将复杂的游戏逻辑提取到 `Logic/` 目录中专门的辅助函数或类型中。通过委托来保持 Reducer 的简洁：

```swift
// Logic/MyNewGameLogic.swift

import CoreEngine

enum MyNewGameLogic {
    /// 检查玩家是否与任何敌人发生碰撞。
    static func checkCollisions(
        playerPosition: CGPoint,
        enemies: [Enemy]
    ) -> Bool {
        // 碰撞逻辑写在这里
        return false
    }

    /// 根据等级计算得分倍率。
    static func scoreMultiplier(for level: Int) -> Int {
        min(level, 10)
    }
}
```

然后在 Reducer 中调用：

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

使用 SwiftUI 构建 UI，并使用共享的 `GameUI` 组件以获得一致的样式。

```swift
import SwiftUI
import CoreEngine
import GameUI

struct MyNewGameView: View {
    let store: StateStore<MyNewGameState, MyNewGameAction>
    @State private var gameState = MyNewGameState()

    var body: some View {
        ZStack {
            // 游戏面板
            MyNewGameBoardView(state: gameState)

            // HUD 叠加层
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

指导原则：
- 使用 `AppTheme` 常量来设置字体、颜色、间距和圆角半径。
- 使用 `GlassCard` 和 `GlassButton` 以实现 iOS 26 的“液态玻璃”外观。
- 订阅 Store 以获取状态更新。
- 通过 `await store.send(...)` 派发 Action。

---

## Step 7: Implement GameDefinition

`GameDefinition` 协议是你的游戏向目录注册的方式：

```swift
public protocol GameDefinition: Sendable {
    var metadata: GameMetadata { get }
    @MainActor func makeRootView() -> AnyView
}
```

在模块的根文件中实现它：

```swift
import SwiftUI
import CoreEngine
import GameCatalog

public struct MyNewGameDefinition: GameDefinition {
    public let metadata = GameMetadata(
        id: "my-new-game",
        displayName: "My New Game",
        description: "一个具有独创机制的有趣新游戏。",
        iconName: "gamecontroller.fill",   // SF Symbol 名称
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

可用类别包括：`.action`, `.puzzle`, `.classic`, `.reflex`。

---

## Step 8: Register with GameRegistry

在主应用目标（`App/`）中，在启动时注册你的游戏。`GameRegistry` 是一个 Actor：

```swift
public actor GameRegistry {
    public func register(_ game: GameDefinition)
    public var allMetadata: [GameMetadata] { get }
    public func game(withID id: String) -> GameDefinition?
}
```

在应用的初始化代码中添加注册：

```swift
await registry.register(MyNewGameDefinition())
```

然后，在应用目标的 `Package.swift` 或 Xcode 项目设置中添加你的软件包作为依赖。

---

## Step 9: Add Configuration (Optional)

对于具有难度级别或可调参数的游戏，创建一个配置结构体：

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

将配置传递到状态的初始化程序中，并在 Reducer 中使用它。

---

## Complete Minimal Example

下面是一个完整的、可编译的游戏模块——一个简单的“点击计数器”游戏，在限定时间内计算点击次数。

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
        description: "在时间耗尽前尽可能快地点击！",
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

因为 Reducer 是纯函数，所以它们非常容易测试：

```swift
let (newState, effect) = myReducer(initialState, .someAction)
#expect(newState.someProperty == expectedValue)
```

测试优先级：
1. **Reducer 测试**——最有价值，包含纯逻辑。
2. **逻辑辅助测试**——对提取出来的算法进行单元测试。
3. **状态不变性测试**——验证状态永远不会进入无效的组合。

---

## Checklist

在提交你的新游戏模块之前：

- [ ] `Package.swift` 可以通过 `swift build --package-path Packages/MyNewGame` 编译
- [ ] State 结构体符合 `GameState`, `Sendable`, `Equatable`
- [ ] Action 枚举符合 `Sendable`
- [ ] Reducer 是一个没有副作用的纯函数
- [ ] 所有的异步/有副作用的操作都使用了 Effect
- [ ] `GameDefinition` 已实现且包含完整的 `GameMetadata`
- [ ] 游戏已在 App 目标的 `GameRegistry` 中注册
- [ ] 视图使用了 `GameUI` 中的 `AppTheme`, `GlassCard` 和 `GlassButton`
- [ ] 所有美术、音效和音乐资源均为原创或获得妥善授权
- [ ] 游戏名称和元数据不引用任何商标名称
- [ ] 已编写并通过 Reducer 测试
- [ ] 游戏在纵向和横向模式下均可正常运行
- [ ] 游戏遵循辅助功能设置（动态字体、VoiceOver）
