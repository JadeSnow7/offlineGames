[English](Architecture.md) | [简体中文](Architecture.zh-Hans.md)

# Architecture

## Table of Contents

1. [概述](#overview)
2. [设计原则](#design-principles)
3. [模块依赖图](#module-dependency-graph)
4. [单向数据流](#unidirectional-data-flow)
5. [StateStore Actor 模式](#statestore-actor-pattern)
6. [Reduce 函数](#reduce-function)
7. [Effect 系统](#effect-system)
8. [渲染管线](#render-pipeline)
9. [RenderCommand 枚举](#rendercommand-enum)
10. [GameLoop Actor](#gameloop-actor)
11. [输入处理](#input-handling)
12. [音频与触感 Actor](#audio-and-haptic-actors)
13. [C++ 互操作层](#c-interop-layer)
14. [数据流图](#data-flow-diagrams)

---

## Overview

offlineGames 使用专门为实时游戏开发适配的 **TCA 风格（The Composable Architecture）单向架构**。该架构强制执行单向数据流：用户输入和系统事件产生 Action，Action 被送入纯 Reduce 函数并返回新的 State 和 Effect，State 的变化驱动渲染，而 Effect 产生异步工作，这些工作可能会将进一步的 Action 反馈回循环中。

这种方法为游戏开发提供了几个优势：

- **确定性的状态转换** —— 每一个状态变更都是已知 Action 的结果，使调试和回放变得非常简单。
- **可测试性** —— Reduce 函数是纯函数，不需要 mock 或 stub。只需输入 State 和 Action，然后对输出的 State 和 Effect 进行断言。
- **并发安全** —— 所有共享的可变状态都存在于 Swift actor 中，在 Swift 6 严格并发检查下消除了数据竞争。
- **渲染与逻辑解耦** —— 游戏逻辑永远不会直接接触 Metal 或 SpriteKit。它发出由渲染管线解释的 RenderCommand。
- **可组合性** —— 每个游戏都是一个独立的 Swift 软件包，可以插入到共享的 CoreEngine 和 App 外壳中。

---

## Design Principles

| 原则 | 描述 |
|---|---|
| 单向流 | 状态向下流动，Action 向上流动。没有双向绑定。 |
| 纯粹核心，有副作用的外壳 | 所有游戏逻辑都是纯粹的。副作用由 Reducer 声明而非执行。 |
| Actor 隔离 | 每一块共享可变状态都是一个 actor。没有类，没有锁。 |
| 协议驱动渲染 | 渲染被抽象在协议之后，因此 Metal 和 SpriteKit 可以互换。 |
| 零第三方依赖 | 整个项目仅依赖 Apple 框架和我们自己的 C++ 核心。 |
| 极简模块化 | 每个文件负责一个职责。每个包有一个用途。 |

---

## Module Dependency Graph

项目被组织为一个分层的依赖图。依赖关系严格向下流动 —— 不允许循环依赖。

```
+----------------------------------------------------------+
|                       App Shell                          |
|  (offlineGamesApp, NavigationCoordinator, GamePicker)    |
+---------------------------+------------------------------+
                            |
            +---------------+----------------+
            |               |                |
   +--------v------+ +-----v-------+ +------v--------+
   | SnakePackage  | | TetrisPackage| | MinesweeperPkg|   <-- 游戏包
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
              | (Swift 封装 / 桥接)         |
              +-------------+--------------+
                            |
              +-------------v--------------+
              |          CppCore           |
              | (C++ 数学, 碰撞检测,        |
              |  噪声, 网格算法)             |
              +----------------------------+
```

### Package Descriptions

- **CppCore** —— 纯 C++ 库，包含性能关键型算法：向量数学、AABB 和圆形碰撞检测、Perlin 噪声、基于网格的路径规划和随机数生成。不依赖 Apple 框架。
- **CppCoreSwift** —— 薄的 Swift 封装层，通过 C++ 互操作导入 CppCore 并提供符合 Swift 习惯的 API。在 C++ 值类型和 Swift 值类型之间进行转换。
- **CoreEngine** —— 架构的核心。包含 StateStore actor、Effect 类型、GameLoop actor、RenderPipeline 协议、RenderCommand 枚举、InputEvent 枚举、AudioActor、HapticActor 以及所有共享协议。每个游戏包都依赖于 CoreEngine。
- **游戏包** (SnakePackage, TetrisPackage, MinesweeperPackage 等) —— 每个游戏都是一个独立的 Swift 包，定义了自己的 State、Action、Reducer、逻辑辅助工具和 SwiftUI 视图。游戏包依赖于 CoreEngine，并可选地依赖于 CppCoreSwift。
- **App Shell** —— 主应用程序目标。包含应用入口点、导航协调器、游戏选择 UI，并将每个游戏包连接到运行中的应用中。App Shell 依赖于所有游戏包和 CoreEngine。

---

## Unidirectional Data Flow

核心数据流循环如下：

```
用户点击按钮
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
State 已发布              Effect 已执行
       |                        |
       v                        |
SwiftUI 重新渲染                 |
发出 RenderCommands              |
       |                        |
       v                        v
RenderPipeline 绘制       异步结果变为新的 Action
                                |
                                v
                        StateStore.send(newAction)
                                |
                                v
                           (循环重复)
```

每个游戏会话只有一个 StateStore。所有对游戏状态的修改都必须通过 reduce 函数。视图观察 Store 发布的状态并重新渲染。Effect 是执行副作用（定时器、音频、触感、持久化）的唯一机制。

---

## StateStore Actor Pattern

`StateStore` 是一个 Swift `actor`，它拥有游戏状态的唯一事实来源。作为一个 Actor，它保证所有状态修改都是序列化的，即使 Action 来自多个并发上下文（UI 线程、游戏循环、网络回调），也能消除数据竞争。

```swift
/// 单个游戏会话的中央状态容器。
/// 所有状态修改都通过此 actor 进行序列化。
public actor StateStore<State: Sendable, Action: Sendable> {

    // MARK: - 属性

    /// 当前状态。每次 reduce 后发布给观察者。
    public private(set) var state: State

    /// 定义状态转换的 reduce 函数。
    private let reduce: (State, Action) -> (State, Effect<Action>)

    /// 用于广播状态更改的流延续（continuation）。
    private var continuations: [UUID: AsyncStream<State>.Continuation] = [:]

    // MARK: - 初始化

    public init(
        initialState: State,
        reduce: @escaping @Sendable (State, Action) -> (State, Effect<Action>)
    ) {
        self.state = initialState
        self.reduce = reduce
    }

    // MARK: - 发送 Action

    /// 通过 reduce 函数处理 action，更新状态，
    /// 通知观察者，并执行任何返回的 effect。
    public func send(_ action: Action) {
        let (newState, effect) = reduce(state, action)
        state = newState

        // 向所有观察者广播新状态。
        for (_, continuation) in continuations {
            continuation.yield(newState)
        }

        // 执行 effect，将产生的结果 action 反馈回 send。
        Task { [weak self] in
            await self?.execute(effect)
        }
    }

    // MARK: - 观察

    /// 返回一个 AsyncStream，它会产生当前状态以及
    /// 之后所有的状态更改。
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

    // MARK: - 私有方法

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

- **Actor 而非 Class** —— 使用 actor 而不是带有锁的类，可以确保在 Swift 6 严格并发下的数据竞争安全性。编译器会强制执行隔离。
- **State 和 Action 的泛型化** —— 同一个 StateStore 驱动每个游戏。Snake、Tetris 和 Minesweeper 各自定义自己的 State 和 Action 类型并将其插入。
- **使用 AsyncStream 进行观察** —— SwiftUI 视图和其他使用者通过 AsyncStream 观察状态更改，这自然地集成了结构化并发和 `.task` 视图修饰符。
- **Effect 执行中的 weak self** —— Effect 捕获 `[weak self]` 以避免在 Effect 运行期间游戏会话被销毁时产生循环引用。

---

## Reduce Function

Reduce 函数是发生状态转换的唯一位置。其签名为：

```swift
(State, Action) -> (State, Effect<Action>)
```

### Characteristics

- **纯粹性** —— 给定相同的 State 和 Action，Reduce 函数总是返回相同的输出 State 和 Effect。没有副作用，没有全局状态访问，没有 I/O。
- **同步性** —— Reduce 函数在 actor 的执行器上同步运行。它绝不能执行阻塞或耗时长的任务。昂贵的计算应放在 Effect 中。
- **完备性** —— Reduce 函数处理每一种可能的 Action。没有静默丢弃 action 的默认/兜底情况。每个 action 都必须明确匹配。
- **同时返回状态和 Effect** —— Reduce 函数不是就地修改状态并命令式地启动副作用，而是声明新状态是什么以及应该发生什么副作用。StateStore 负责应用状态并执行 Effect。

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

由于 Reducer 是纯函数，测试变得非常简单：

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

不需要 mock。不需要依赖注入容器。不需要 setup/teardown 的仪式感。输入状态和 Action，对输出进行断言。

---

## Effect System

`Effect` 类型是一个枚举，它在不执行的情况下声明了副作用。StateStore 负责在 reduce 函数返回后解释并执行这些 Effect。

```swift
/// 声明由 StateStore 执行的副作用。
/// Effect 是游戏逻辑与外部世界交互的唯一方式。
public enum Effect<Action: Sendable>: Sendable {

    /// 无副作用。最常见的情况 —— 大多数 action 只改变状态。
    case none

    /// 可能会产生新 Action 的异步操作。
    /// 返回的 action（如果有）将被反馈回 StateStore。
    case run(@Sendable () async -> Action?)

    /// 不产生 Action 的异步操作。
    /// 用于“发完即忘”的工作，如播放音频或触发触感。
    case fireAndForget(@Sendable () async -> Void)

    /// 并发执行多个 effect。
    /// batch 中的所有 effect 将通过 TaskGroup 并行运行。
    case batch([Effect<Action>])
}
```

### Effect Variants in Detail

#### `Effect.none`

恒等效应。用于当 action 仅更改状态且不需要副作用时。这是最常见的返回值。

```swift
case .changeDirection(let dir):
    state.direction = dir
    return (state, .none)
```

#### `Effect.run`

可能会产生后续 Action 的异步操作。闭包在分离的上下文中运行。如果它返回一个 Action，该 action 会被发送回 StateStore，继续循环。如果返回 `nil`，则循环结束。

常见用途：
- 定时器（休眠后返回 `.tick`）
- 从磁盘加载数据（返回 `.dataLoaded(data)`）
- 网络请求（返回 `.responseReceived(response)`）

```swift
case .startGame:
    state.phase = .playing
    return (state, .run {
        try? await Task.sleep(for: .seconds(1))
        return .tick
    })
```

#### `Effect.fireAndForget`

执行工作但不产生后续 Action 的异步操作。StateStore 执行它并丢弃结果。

常见用途：
- 播放音效
- 触发触感反馈
- 记录分析数据
- 持久化高分

```swift
return (state, .fireAndForget {
    await AudioActor.shared.play(.lineClear)
})
```

#### `Effect.batch`

并发执行多个 effect。数组中的每个 effect 都作为 `TaskGroup` 中的一个独立子任务运行。当一个 action 需要触发多个独立的副作用时使用此项。

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

Effect 可以自然地组合。辅助函数可以返回一个 Effect，而调用者可以将其合并到一个 batch 中：

```swift
func playFeedback(sound: SoundEffect, haptic: HapticPattern) -> Effect<SnakeAction> {
    .batch([
        .fireAndForget { await AudioActor.shared.play(sound) },
        .fireAndForget { await HapticActor.shared.trigger(haptic) }
    ])
}

// 在 reducer 中：
return (state, .batch([
    playFeedback(sound: .eat, haptic: .light),
    .run { ... }
]))
```

---

## Render Pipeline

`RenderPipeline` 协议抽象了渲染后端。游戏逻辑从不直接导入 Metal、SpriteKit 或任何渲染框架。相反，它发出 `RenderCommand` 值，由管线进行解释。

```swift
/// 渲染后端的抽象。
/// 存在 Metal（高性能）和 SpriteKit（快速原型设计）的实现。
public protocol RenderPipeline: Sendable {

    /// 在第一帧之前准备所需的资源。
    func setup(viewportSize: CGSize) async

    /// 使用提供的渲染命令渲染一帧。
    func render(commands: [RenderCommand]) async

    /// 处理视口大小调整（设备旋转、窗口缩放）。
    func resize(to size: CGSize) async

    /// 释放所有 GPU 资源。
    func teardown() async
}
```

### Metal Implementation

`MetalRenderPipeline` 是发布游戏的主要渲染器。它管理 `MTLDevice`、命令队列、渲染通道描述符和管线状态对象。它按纹理图集对绘制调用进行批处理，并使用三倍缓冲信号量来确保顺畅的帧率。

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
        // 加载着色器，创建管线状态对象，
        // 分配顶点/索引缓冲区，加载纹理图集。
    }

    public func render(commands: [RenderCommand]) async {
        // 按层级排序命令，按纹理批处理，
        // 将绘制调用编码到命令缓冲区并提交。
    }

    public func resize(to size: CGSize) async {
        // 重新创建深度/模板纹理，更新投影矩阵。
    }

    public func teardown() async {
        // 释放所有 Metal 资源。
    }
}
```

### SpriteKit Implementation

`SpriteKitRenderPipeline` 用于快速原型设计以及那些 SpriteKit 内置物理或粒子系统很有用的游戏。它将 RenderCommand 转换为 SKNode 树的修改。

```swift
public actor SpriteKitRenderPipeline: RenderPipeline {

    private weak var scene: SKScene?

    public init(scene: SKScene) {
        self.scene = scene
    }

    public func render(commands: [RenderCommand]) async {
        guard let scene else { return }
        // 将命令与当前节点树进行对比（diff），
        // 根据需要添加/移除/更新 SKNode。
    }

    // ...
}
```

### Choosing a Pipeline

管线在创建游戏会话时注入。App Shell 根据游戏需求决定使用哪个管线：

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

`RenderCommand` 是一种值类型，用于描述要绘制的内容而不引用任何渲染 API。它是游戏逻辑和渲染管线之间的桥梁。

```swift
/// 渲染内容的声明式描述。
/// 游戏逻辑产生这些命令；RenderPipeline 消费它们。
public enum RenderCommand: Sendable, Equatable {

    /// 绘制一个填充矩形。
    case fillRect(
        rect: CGRect,
        color: GameColor,
        layer: Int
    )

    /// 从纹理图集中绘制一个精灵。
    case sprite(
        textureName: String,
        position: CGPoint,
        size: CGSize,
        rotation: Float,
        opacity: Float,
        layer: Int
    )

    /// 绘制文本标签。
    case text(
        content: String,
        position: CGPoint,
        font: GameFont,
        color: GameColor,
        alignment: TextAlignment,
        layer: Int
    )

    /// 在两点之间画线。
    case line(
        from: CGPoint,
        to: CGPoint,
        width: Float,
        color: GameColor,
        layer: Int
    )

    /// 绘制填充圆。
    case circle(
        center: CGPoint,
        radius: Float,
        color: GameColor,
        layer: Int
    )

    /// 设置本帧的背景清除颜色。
    case clearColor(GameColor)

    /// 应用本帧的摄像机变换。
    case camera(
        position: CGPoint,
        zoom: Float,
        rotation: Float
    )
}
```

### Why an Enum?

使用枚举而非直接调用 API 提供了：

- **后端独立性** —— 同样的游戏逻辑可以在 Metal、SpriteKit 或未来任何后端上渲染。
- **可测试性** —— 可以对状态产生的 RenderCommand 进行断言，而不需要 GPU。
- **可序列化** —— RenderCommand 可以被记录下来用于回放或调试。
- **差异对比（Diffing）** —— 管线可以将本帧的命令与上一帧进行对比，以减少 GPU 工作量。

### Generating RenderCommands from State

每个游戏都提供一个 `renderCommands(from:)` 函数，将其 State 转换为 RenderCommand 数组：

```swift
func renderCommands(from state: SnakeState) -> [RenderCommand] {
    var commands: [RenderCommand] = [
        .clearColor(.background)
    ]

    // 绘制网格
    for x in 0..<state.gridSize.width {
        for y in 0..<state.gridSize.height {
            let rect = gridCellRect(x: x, y: y, cellSize: state.cellSize)
            let color: GameColor = (x + y).isMultiple(of: 2) ? .gridLight : .gridDark
            commands.append(.fillRect(rect: rect, color: color, layer: 0))
        }
    }

    // 绘制蛇
    for (index, segment) in state.snake.segments.enumerated() {
        let rect = gridCellRect(x: segment.x, y: segment.y, cellSize: state.cellSize)
        let color: GameColor = index == 0 ? .snakeHead : .snakeBody
        commands.append(.fillRect(rect: rect, color: color, layer: 1))
    }

    // 绘制食物
    let foodRect = gridCellRect(x: state.food.position.x, y: state.food.position.y, cellSize: state.cellSize)
    commands.append(.sprite(
        textureName: "food_apple",
        position: CGPoint(x: foodRect.midX, y: foodRect.midY),
        size: foodRect.size,
        rotation: 0,
        opacity: 1,
        layer: 1
    ))

    // 绘制分数
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

`GameLoop` actor 提供了一个独立于显示刷新率的**固定时间步长游戏滴答（fixed-timestep game tick）**。这确保了物理和游戏逻辑的确定性，不受帧率波动的影响。

```swift
/// 以固定的滴答速率驱动游戏，与显示刷新率解耦。
public actor GameLoop {

    // MARK: - 配置

    /// 目标每秒滴答数。
    public let tickRate: Int

    /// 每个滴答的固定时间步长（秒）。
    public var tickInterval: Duration {
        .seconds(1.0 / Double(tickRate))
    }

    // MARK: - 状态

    private var isRunning = false
    private var accumulatedTime: Duration = .zero
    private var lastFrameTime: ContinuousClock.Instant?
    private var tickAction: (@Sendable () async -> Void)?

    // MARK: - 初始化

    public init(tickRate: Int = 60) {
        self.tickRate = tickRate
    }

    // MARK: - 控制

    /// 启动游戏循环。提供的闭包在每个固定滴答被调用一次。
    public func start(onTick: @escaping @Sendable () async -> Void) {
        guard !isRunning else { return }
        isRunning = true
        tickAction = onTick
        lastFrameTime = ContinuousClock.now

        Task { [weak self] in
            await self?.runLoop()
        }
    }

    /// 停止游戏循环。
    public func stop() {
        isRunning = false
        tickAction = nil
        lastFrameTime = nil
        accumulatedTime = .zero
    }

    /// 暂停游戏循环而不重置累积时间。
    public func pause() {
        isRunning = false
    }

    /// 从暂停处恢复游戏循环。
    public func resume() {
        guard !isRunning, tickAction != nil else { return }
        isRunning = true
        lastFrameTime = ContinuousClock.now

        Task { [weak self] in
            await self?.runLoop()
        }
    }

    // MARK: - 私有方法

    private func runLoop() async {
        while isRunning {
            let now = ContinuousClock.now
            let elapsed = now - (lastFrameTime ?? now)
            lastFrameTime = now
            accumulatedTime += elapsed

            // 处理已经累积的固定滴答。
            // 设定上限以防止“死亡螺旋”。
            var ticksThisFrame = 0
            let maxTicksPerFrame = 5

            while accumulatedTime >= tickInterval && ticksThisFrame < maxTicksPerFrame {
                await tickAction?()
                accumulatedTime -= tickInterval
                ticksThisFrame += 1
            }

            // 如果达到上限，丢弃剩余累积时间
            // 以防止死亡螺旋。
            if ticksThisFrame >= maxTicksPerFrame {
                accumulatedTime = .zero
            }

            // 短暂休眠以让出执行器。
            try? await Task.sleep(for: .milliseconds(1))
        }
    }
}
```

### Fixed Timestep Explained

固定时间步长模式将游戏逻辑更新的速率与帧显示的速率分离开来：

```
显示：  |----16ms----|----16ms----|----16ms----|  (60 FPS)
逻辑：  |--10ms--|--10ms--|--10ms--|--10ms--|       (100 ticks/sec)
```

在每一个显示帧中，循环会计算流逝的实际时间，进行累积，并处理尽可能多的固定时长滴答。这意味着：

- 在 60 FPS 且滴答速率为 100 时，大多数帧处理 1-2 个滴答。
- 在 30 FPS（例如由于发热降频）时，每一帧处理 3-4 个滴答。
- 游戏逻辑始终以相同的有效速度运行。

### Spiral of Death Protection

如果设备极其缓慢，且每个滴答耗时超过滴答间隔，滴答的积累速度会超过处理速度。`maxTicksPerFrame` 上限通过丢弃超出的累积时间来防止这种情况，宁愿选择瞬间的卡顿，也不愿永久死机。

---

## Input Handling

所有用户输入在进入架构之前都会被标准化为单个 `InputEvent` 枚举。这使游戏逻辑与具体的输入机制（触摸、手柄、键盘）解耦。

```swift
/// 标准化输入事件。游戏逻辑只看这些事件，
/// 永远不看原始的 UITouch、GCController 或 UIKey 事件。
public enum InputEvent: Sendable, Equatable {

    // MARK: - 触摸 / 指针

    case touchBegan(position: CGPoint, id: Int)
    case touchMoved(position: CGPoint, id: Int)
    case touchEnded(position: CGPoint, id: Int)
    case touchCancelled(id: Int)

    // MARK: - 方向性

    case swipe(direction: Direction)
    case joystick(x: Float, y: Float)  // 归一化 -1...1

    // MARK: - 按钮

    case buttonDown(GameButton)
    case buttonUp(GameButton)

    // MARK: - 键盘 (iPad, Mac Catalyst)

    case keyDown(KeyCode)
    case keyUp(KeyCode)

    // MARK: - 系统

    case appDidEnterBackground
    case appWillEnterForeground
}

/// 基本方向和间接方向。
public enum Direction: Sendable, Equatable {
    case up, down, left, right
    case upLeft, upRight, downLeft, downRight
}

/// 逻辑游戏按钮，独立于物理输入设备。
public enum GameButton: Sendable, Equatable {
    case primary    // A / 点击 / 单击
    case secondary  // B / 长按 / 右键单击
    case pause      // Start / 菜单按钮
    case dpadUp, dpadDown, dpadLeft, dpadRight
}
```

### Input Translation

每个输入源都有一个转换器，将原始事件转换为 `InputEvent` 值：

```swift
/// 将原始 UIKit 手势识别器事件转换为 InputEvent 值。
struct TouchInputTranslator {
    func translate(gesture: UIGestureRecognizer, in view: UIView) -> InputEvent? {
        // 识别轻扫、点击等并返回相应的 InputEvent。
    }
}

/// 将游戏控制器事件转换为 InputEvent 值。
struct GamepadInputTranslator {
    func translate(element: GCControllerElement) -> InputEvent? {
        // 将物理按钮和摇杆映射到 InputEvent。
    }
}
```

### From InputEvent to Action

每个游戏定义了从 `InputEvent` 到其特定游戏 `Action` 类型的映射：

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

音频播放和触感反馈由专门的 actor 管理。这些是全局单例（每个设备一个音频系统，一个触感引擎），但其 actor 隔离特性使得并发访问是安全的。

### AudioActor

```swift
/// 管理应用程序的所有音频播放。
/// 使用 AVAudioEngine 处理低延迟音效，
/// 使用 AVAudioPlayer 处理背景音乐。
public actor AudioActor {

    public static let shared = AudioActor()

    private var engine: AVAudioEngine?
    private var soundBuffers: [SoundEffect: AVAudioPCMBuffer] = [:]
    private var musicPlayer: AVAudioPlayer?
    private var isMuted: Bool = false
    private var volume: Float = 1.0

    // MARK: - 设置

    /// 将所有音效预加载到内存中以实现低延迟播放。
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

    // MARK: - 播放

    /// 播放预加载的音效。
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

    /// 开始循环播放背景音乐。
    public func playMusic(_ music: MusicTrack) {
        guard let url = Bundle.main.url(forResource: music.filename, withExtension: "m4a") else { return }
        musicPlayer = try? AVAudioPlayer(contentsOf: url)
        musicPlayer?.numberOfLoops = -1
        musicPlayer?.volume = volume * 0.5
        musicPlayer?.play()
    }

    /// 停止所有音频播放。
    public func stopAll() {
        engine?.stop()
        musicPlayer?.stop()
    }

    // MARK: - 设置项

    public func setMuted(_ muted: Bool) { isMuted = muted }
    public func setVolume(_ newVolume: Float) { volume = newVolume.clamped(to: 0...1) }
}
```

### HapticActor

```swift
/// 使用 CoreHaptics 管理触感反馈。
/// 在不支持触感引擎的设备上平稳回退。
public actor HapticActor {

    public static let shared = HapticActor()

    private var engine: CHHapticEngine?
    private var isSupported: Bool = false
    private var isEnabled: Bool = true

    // MARK: - 设置

    public func setup() async {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            isSupported = false
            return
        }
        isSupported = true
        engine = try? CHHapticEngine()
        try? engine?.start()

        // 如果引擎因应用生命周期停止，则重新启动。
        engine?.stoppedHandler = { [weak self] _ in
            Task { await self?.restart() }
        }
    }

    // MARK: - 触发

    /// 触发预定义的触感模式。
    public func trigger(_ pattern: HapticPattern) {
        guard isSupported, isEnabled, let engine else { return }
        let events = pattern.hapticEvents
        guard let hapticPattern = try? CHHapticPattern(events: events, parameters: []),
              let player = try? engine.makePlayer(with: hapticPattern) else { return }
        try? player.start(atTime: CHHapticTimeImmediate)
    }

    // MARK: - 设置项

    public func setEnabled(_ enabled: Bool) { isEnabled = enabled }

    // MARK: - 私有方法

    private func restart() {
        try? engine?.start()
    }
}

/// 预定义的触感反馈模式。
public enum HapticPattern: Sendable {
    case light      // 微弱震动 (放置方块)
    case medium     // 中等震动 (消除行)
    case heavy      // 强烈震动 (游戏结束)
    case success    // 上升模式 (获得高分)
    case warning    // 下降模式 (危险)
    case selection  // 微小的滴答声 (菜单导航)

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
        // ... 其他模式
        default:
            return []
        }
    }
}
```

---

## C++ Interop Layer

性能关键型算法使用 C++ 实现，并通过 Swift 的原生 C++ 互操作性桥接到 Swift。互操作层分为两个包：

### CppCore (Pure C++)

CppCore 是一个仅包含头文件（或已编译）的 C++ 库，不依赖 Apple 框架。它可以使用任何 C++ 测试框架进行单元测试。所有代码都位于 `cppcore` 命名空间中。

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

/// 2D 网格上的广度优先搜索。返回从起点到终点的最短路径，
/// 如果不存在路径，则返回空向量。
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
                // 重构路径。
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
    return {}; // 未找到路径。
}

} // namespace cppcore
```

### CppCoreSwift (Swift Overlay)

CppCoreSwift 导入 C++ 类型并提供 Swift 友好的包装：

```swift
// CppCoreSwift/Sources/Vector2.swift

import CppCore

/// cppcore::Vec2 的 Swift 包装。
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

在以下情况下使用 C++ (通过 CppCore)：

- 算法在紧密循环中处理大型数组（跨数百个实体的碰撞检测）。
- 算法受益于连续的内存布局（网格操作）。
- 算法是众所周知的数值方法，已有成熟的 C++ 实现。
- 分析显示 Swift 实现在某些环节成为瓶颈。

在以下情况下**不**使用 C++：

- 代码是胶水逻辑、UI 或状态管理。
- 性能差异可以忽略不计（少于 1000 次迭代）。
- 算法足够简单，Swift 的优化器可以很好地处理。

---

## Data Flow Diagrams

### Complete System Data Flow

```
+---------------------+
|      用户输入        |  触摸, 手柄, 键盘
+----------+----------+
           |
           v
+----------+----------+
| InputEvent 转换器    |  原始事件 -> InputEvent 枚举
+----------+----------+
           |
           v
+----------+----------+
|    输入映射器        |  InputEvent -> 特定游戏的 Action
+----------+----------+
           |
           v
+----------+----------+
|     StateStore       |  Actor: 序列化所有状态更改
|  +----------------+  |
|  | reduce(s, a)   |  |  纯函数: (State, Action) -> (State, Effect)
|  |  -> (s', eff)  |  |
|  +-------+--------+  |
|          |            |
|  +-------v--------+  |
|  |   应用状态      |  |  state = newState
|  +-------+--------+  |
|          |            |
|  +-------v--------+  |
|  |   执行 Effect   |  |  异步: 定时器, 音频, 触感, 持久化
|  +-------+--------+  |
+----------+----------+
           |
     +-----+------+
     |            |
     v            v
+----+-----+ +---+----+
| 观察者   | | Effects  |
| (SwiftUI,| |(音频,   |
|  渲染器)  | | 触感,   |
+----+-----+ | 定时器)  |
     |        +---+----+
     v            |
+----+---------+  |  Action 反馈
| renderCmds() |  +-----> StateStore.send(action)
+----+---------+
     |
     v
+----+-----------+
| 渲染管线        |  Metal 或 SpriteKit
+----------------+
     |
     v
  [屏幕]
```

### Game Session Lifecycle

```
应用启动
    |
    v
GamePicker (SwiftUI)
    |
    | 用户选择一个游戏
    v
NavigationCoordinator
    |
    | 创建游戏会话
    v
+-- 游戏会话创建 --+
|                 |
|  1. 创建初始 State  |
|  2. 创建 StateStore |
|     带有 reduce 函数 |
|  3. 创建渲染管线     |
|     (Metal/SK)  |
|  4. 创建 GameLoop   |
|  5. 预加载音频      |
|  6. 设置触感        |
|                 |
+-------------+-------------+
              |
              v
           游戏运行
        (滴答循环激活)
              |
    +---------+---------+
    |         |         |
    v         v         v
  暂停      游戏结束    退出
    |         |         |
    v         v         |
  继续      重启        |
    |         |         |
    v         v         |
 (回到运行)  (回到运行)  |
              |         |
              v         v
           会话销毁
              |
              v
        1. 停止 GameLoop
        2. 停止音频
        3. 销毁管线
        4. 释放 StateStore
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
    | 派生自 State 的 @Published 属性
    v
GameView (SwiftUI)
    |
    | 状态改变时重绘 body
    v
Canvas / Metal view
    |
    | RenderCommands
    v
RenderPipeline.render(commands:)
```

### Module Dependency Direction

```
不依赖于任何东西:
  CppCore

依赖于 CppCore:
  CppCoreSwift

依赖于 CppCoreSwift + Apple 框架:
  CoreEngine

依赖于 CoreEngine:
  SnakePackage
  TetrisPackage
  MinesweeperPackage
  (未来的游戏包)

依赖于 CoreEngine + 所有游戏包:
  App (offlineGamesApp)
```

### Effect Execution Timeline

```
时间 ──────────────────────────────────────────────>

Action 到达            Effect 执行                新 action 到达
     |                       |                          |
     v                       v                          v
┌─────────┐  ┌───────────────────────────┐  ┌─────────┐
│ reduce() │  │ Effect.run { sleep; .tick }│  │ reduce() │
│ 同步     │  │ 异步                       │  │ 同步     │
└─────────┘  └───────────────────────────┘  └─────────┘
     |                                           |
     v                                           v
 状态已更新                                  状态已更新
 通知观察者                                  通知观察者
 帧已渲染                                    帧已渲染
```

---

## Summary

该架构可以总结为五条规则：

1. **所有状态都存储在 StateStore actor 中。** 每个游戏会话有一个 store。其他任何地方都不持有可变的游戏状态。
2. **状态仅通过 reduce 函数改变。** 每次修改都是由纯函数处理派发的 Action 的结果。
3. **副作用是声明式的，而不是命令式的。** Reduce 函数返回 Effect 值，由 StateStore 负责解释执行它们。
4. **渲染是状态的纯函数。** `renderCommands(from:)` 将 State 转换为 RenderCommand，由 RenderPipeline 负责绘制。
5. **一切皆可发送 (Sendable)。** 跨越隔离边界的每个类型都符合 Sendable 协议，由 Swift 6 严格并发机制强制执行。
