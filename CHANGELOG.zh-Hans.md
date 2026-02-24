[English](CHANGELOG.md) | [简体中文](CHANGELOG.zh-Hans.md)

# Changelog

本文件将记录本项目的所有显著更改。

本文件的格式基于 [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)，且本项目遵循 [语义化版本](https://semver.org/spec/v2.0.0.html) 规范。

## [Unreleased]

### Added
- 包含 12 个 SPM 软件包的项目骨架
- CoreEngine：`GameState`、`Reduce`、`Effect`、`StateStore`、`GameLoop`、`InputEvent`、`RenderCommand`、`RenderPipeline`
- CoreEngine：`AudioEngine`、`HapticEngine`、`HighScoreStore`、`SettingsStore` actor
- MetalRenderer：`MetalContext`、顶点/片段着色器、`ShaderTypes`
- SpriteKitRenderer：`SpriteKitContext` 场景
- CppCore：`CollisionDetection`、`GridAlgorithms`、`PhysicsTypes` (C++20)
- GameUI：`AppTheme`、`GlassCard`、`GlassButton`、`AppRouter`
- GameCatalog：`GameDefinition`、`GameMetadata`、`GameRegistry`
- 游戏骨架：`Snake`、`BlockPuzzle`、`Breakout`、`Minesweeper`、`MemoryMatch`、`ReactionTap`
- 带有 `@main` 入口点的应用外壳
- 项目文档（架构、编码标准、模块指南等）
- 构建脚本 (`run_tests.sh`, `lint.sh`)
- `SwiftLint` 配置
