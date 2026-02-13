# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Project skeleton with 12 SPM packages
- CoreEngine: GameState, Reduce, Effect, StateStore, GameLoop, InputEvent, RenderCommand, RenderPipeline
- CoreEngine: AudioEngine, HapticEngine, HighScoreStore, SettingsStore actors
- MetalRenderer: MetalContext, vertex/fragment shaders, ShaderTypes
- SpriteKitRenderer: SpriteKitContext scene
- CppCore: CollisionDetection, GridAlgorithms, PhysicsTypes (C++20)
- GameUI: AppTheme, GlassCard, GlassButton, AppRouter
- GameCatalog: GameDefinition, GameMetadata, GameRegistry
- Game skeletons: Snake, BlockPuzzle, Breakout, Minesweeper, MemoryMatch, ReactionTap
- App shell with @main entry point
- Project documentation (Architecture, Coding Standards, Module Guide, etc.)
- Build scripts (run_tests.sh, lint.sh)
- SwiftLint configuration
