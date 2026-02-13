# Contributing

Thank you for your interest in contributing to Offline Games!

## Development Setup

1. Clone the repository
2. Open the project in Xcode 26+
3. Each package under `Packages/` is an independent SPM package

## Code Style

This project enforces strict coding standards. Please read [Docs/CodingStandards.md](Docs/CodingStandards.md) before contributing.

### Key Rules

- **One file, one type**: Every public type/protocol gets its own file, named after the type
- **Pure functions**: Game logic lives in `Reduce` functions — `(State, Action) -> (State, Effect)`
- **Actor isolation**: All shared mutable state is an Actor (`StateStore`, `AudioEngine`, etc.)
- **Swift 6 concurrency**: All types must be `Sendable`; no data races
- **No third-party dependencies**: Everything is built from scratch
- **No force unwraps**: Use `guard let` or optional chaining

### File Length Limits

- Max 400 lines per file (warning), 500 (error)
- Max 40 lines per function body (warning), 60 (error)
- If a file or function is too long, split it

### Game Module Structure

Each game package follows this template:

```
GameName/
├── Sources/GameName/
│   ├── GameNameState.swift      # State struct conforming to GameState
│   ├── GameNameAction.swift     # Action enum
│   ├── GameNameReducer.swift    # Pure Reduce function
│   ├── GameNameLogic.swift      # Helper pure functions (optional)
│   └── GameNameView.swift       # SwiftUI view (optional)
└── Tests/GameNameTests/
    └── GameNameTests.swift
```

## Running Tests

```bash
./Scripts/run_tests.sh
```

For packages requiring iOS Simulator, use Xcode's test runner.

## Linting

```bash
./Scripts/lint.sh
```

Requires [SwiftLint](https://github.com/realm/SwiftLint): `brew install swiftlint`

## Pull Request Guidelines

1. Create a feature branch from `main`
2. Keep commits focused and atomic
3. Ensure all tests pass
4. Run the linter before submitting
5. Provide a clear description of changes

## Adding a New Game

See [Docs/ModuleGuide.md](Docs/ModuleGuide.md) for step-by-step instructions.

## IP Guidelines

All game implementations must use original names, art, and sound. See [Docs/IPConsiderations.md](Docs/IPConsiderations.md) for details.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
