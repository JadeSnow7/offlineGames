[English](README.md) | [简体中文](README.zh-Hans.md)

# Offline Games

A collection of classic and original offline mini-games for iOS, built with SwiftUI, Metal, and SpriteKit.

## Features

- **6 Games**: Snake, Block Puzzle, Breakout, Minesweeper, Memory Match, Reaction Tap
- **iOS 26 Liquid Glass** design language
- **100% offline** — no network, no ads, no tracking
- **Zero third-party dependencies**
- **Swift 6** strict concurrency with Actor model
- **Metal** rendering for action games
- **SpriteKit** rendering for grid/tile games
- **C++ interop** for performance-critical algorithms

## Requirements

- Xcode 26.0+
- iOS 26.0+ deployment target
- macOS 26.0+ (for building)

## Project Structure

```
offlineGames/
├── App/                     # Thin shell app target (@main entry)
├── Packages/
│   ├── CoreEngine/          # Shared game engine (loop, store, input, audio, haptics)
│   ├── MetalRenderer/       # Metal GPU rendering pipeline
│   ├── SpriteKitRenderer/   # SpriteKit rendering for grid games
│   ├── CppCore/             # C++ performance modules (collision, grid, pathfinding)
│   ├── GameUI/              # Shared SwiftUI components (Liquid Glass theme)
│   ├── GameCatalog/         # Game registry and metadata
│   ├── SnakeGame/           # Snake game
│   ├── BlockPuzzle/         # Block puzzle game (original pieces)
│   ├── BreakoutGame/        # Brick breaker game
│   ├── MinesweeperGame/     # Minesweeper
│   ├── MemoryMatch/         # Memory card matching (original)
│   └── ReactionTap/         # Reaction speed test (original)
├── Docs/                    # Project documentation
├── Scripts/                 # Build and test scripts
└── Resources/               # Shared resources
```

## Building

Each package can be built independently:

```bash
swift build --package-path Packages/CoreEngine
```

Run all testable packages:

```bash
./Scripts/run_tests.sh
```

Packages that depend on iOS frameworks (Metal, UIKit, SpriteKit) require Xcode and an iOS Simulator.

## Architecture

The app follows a **TCA-style unidirectional data flow**:

```
User Input → Action → Reducer(State, Action) → (NewState, Effect)
                                                      ↓
                                               Render Commands → GPU
```

See [Docs/Architecture.md](Docs/Architecture.md) for full details.

## Documentation

- [Architecture](Docs/Architecture.md) — System architecture and design decisions
- [Coding Standards](Docs/CodingStandards.md) — Coding conventions and rules
- [Module Guide](Docs/ModuleGuide.md) — How to add a new game module
- [C++ Bridging](Docs/CppBridging.md) — C++ interop guide
- [Metal Pipeline](Docs/MetalPipeline.md) — Metal rendering pipeline docs
- [Localization](Docs/Localization.md) — Localization guide
- [IP Considerations](Docs/IPConsiderations.md) — Intellectual property analysis
- [App Store Checklist](Docs/AppStoreChecklist.md) — App Store submission checklist
- [App Store Launch Copy](Docs/AppStoreLaunchCopy.md) — Ready-to-use US launch metadata copy

## License

MIT — see [LICENSE](LICENSE).
