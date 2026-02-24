[English](README.md) | [简体中文](README.zh-Hans.md)

# Offline Games

一系列为 iOS 打造的经典及原创单机小游戏合集，使用 SwiftUI、Metal 和 SpriteKit 构建。

## Features

- **6 款游戏**：贪吃蛇、方块拼图、打砖块、扫雷、记忆配对、反应点击
- **iOS 26 Liquid Glass** 设计语言
- **100% 离线** —— 无网络、无广告、无追踪
- **零第三方依赖**
- **Swift 6** 严格并发与 Actor 模型
- **Metal** 渲染动作类游戏
- **SpriteKit** 渲染网格/瓷砖类游戏
- **C++ 互操作** 用于性能关键型算法

## Requirements

- Xcode 26.0+
- iOS 26.0+ 部署目标
- macOS 26.0+（用于构建）

## Project Structure

```
offlineGames/
├── App/                     # 瘦壳应用目标（@main 入口）
├── Packages/
│   ├── CoreEngine/          # 共享游戏引擎（循环、存储、输入、音频、触感）
│   ├── MetalRenderer/       # Metal GPU 渲染管线
│   ├── SpriteKitRenderer/   # 网格类游戏的 SpriteKit 渲染
│   ├── CppCore/             # C++ 性能模块（碰撞检测、网格、寻路）
│   ├── GameUI/              # 共享 SwiftUI 组件（Liquid Glass 主题）
│   ├── GameCatalog/         # 游戏注册与元数据
│   ├── SnakeGame/           # 贪吃蛇游戏
│   ├── BlockPuzzle/         # 方块拼图游戏（原创方块）
│   ├── BreakoutGame/        # 打砖块游戏
│   ├── MinesweeperGame/     # 扫雷
│   ├── MemoryMatch/         # 记忆卡片配对（原创）
│   └── ReactionTap/         # 反应速度测试（原创）
├── Docs/                    # 项目文档
├── Scripts/                 # 构建与测试脚本
└── Resources/               # 共享资源
```

## Building

每个包都可以独立构建：

```bash
swift build --package-path Packages/CoreEngine
```

运行所有可测试的包：

```bash
./Scripts/run_tests.sh
```

依赖于 iOS 框架（Metal、UIKit、SpriteKit）的包需要 Xcode 和 iOS 模拟器。

## Architecture

本应用遵循 **TCA 风格的单向数据流**：

```
User Input → Action → Reducer(State, Action) → (NewState, Effect)
                                                      ↓
                                               Render Commands → GPU
```

详见 [Docs/Architecture.md](Docs/Architecture.zh-Hans.md)。

## Documentation

- [Architecture](Docs/Architecture.zh-Hans.md) — 系统架构与设计决策
- [Coding Standards](Docs/CodingStandards.zh-Hans.md) — 编码规范与规则
- [Module Guide](Docs/ModuleGuide.zh-Hans.md) — 如何添加新的游戏模块
- [C++ Bridging](Docs/CppBridging.zh-Hans.md) — C++ 互操作指南
- [Metal Pipeline](Docs/MetalPipeline.zh-Hans.md) — Metal 渲染管线文档
- [Localization](Docs/Localization.zh-Hans.md) — 本地化指南
- [IP Considerations](Docs/IPConsiderations.zh-Hans.md) — 知识产权考量
- [App Store Checklist](Docs/AppStoreChecklist.zh-Hans.md) — App Store 提交检查清单
- [App Store Launch Copy](Docs/AppStoreLaunchCopy.zh-Hans.md) — 可直接使用的美国区首发文案

## License

MIT — 详见 [LICENSE](LICENSE)。
