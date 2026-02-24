[English](CONTRIBUTING.md) | [简体中文](CONTRIBUTING.zh-Hans.md)

# Contributing

感谢您有兴趣为 Offline Games 做出贡献！

## Development Setup

1. 克隆仓库
2. 在 Xcode 26+ 中打开项目
3. `Packages/` 下的每个包都是一个独立的 SPM 包

## Code Style

本项目执行严格的代码标准。在贡献之前，请阅读 [Docs/CodingStandards.md](Docs/CodingStandards.zh-Hans.md)。

### Key Rules

- **一个文件，一个类型**：每个公开类型/协议都有自己的文件，并以该类型命名
- **纯函数**：游戏逻辑存在于 `Reduce` 函数中 — `(State, Action) -> (State, Effect)`
- **Actor 隔离**：所有共享的可变状态都是 Actor（如 `StateStore`、`AudioEngine` 等）
- **Swift 6 并发**：所有类型必须是 `Sendable`；无数据竞争
- **无第三方依赖**：所有内容均从零开始构建
- **禁止强制解包**：使用 `guard let` 或可选链

### File Length Limits

- 每文件最多 400 行（警告），500 行（错误）
- 每函数体最多 40 行（警告），60 行（错误）
- 如果文件或函数过长，请进行拆分

### Game Module Structure

每个游戏包都遵循此模板：

```
GameName/
├── Sources/GameName/
│   ├── GameNameState.swift      # 符合 GameState 协议的状态结构体
│   ├── GameNameAction.swift     # Action 枚举
│   ├── GameNameReducer.swift    # 纯 Reduce 函数
│   ├── GameNameLogic.swift      # 辅助纯函数（可选）
│   └── GameNameView.swift       # SwiftUI 视图（可选）
└── Tests/GameNameTests/
    └── GameNameTests.swift
```

## Running Tests

```bash
./Scripts/run_tests.sh
```

对于需要 iOS 模拟器的包，请使用 Xcode 的测试运行器。

## Linting

```bash
./Scripts/lint.sh
```

需要 [SwiftLint](https://github.com/realm/SwiftLint)：`brew install swiftlint`

## Pull Request Guidelines

1. 从 `main` 分支创建一个功能分支
2. 保持提交（commit）聚焦且原子化
3. 确保所有测试均通过
4. 提交前运行 Linter
5. 提供变更内容的清晰描述

## Adding a New Game

请参阅 [Docs/ModuleGuide.md](Docs/ModuleGuide.zh-Hans.md) 了解分步指南。

## IP Guidelines

所有游戏实现必须使用原创的名称、美术和音效。详见 [Docs/IPConsiderations.md](Docs/IPConsiderations.zh-Hans.md)。

## License

通过贡献，即表示您同意您的贡献将根据 MIT 许可证进行授权。
