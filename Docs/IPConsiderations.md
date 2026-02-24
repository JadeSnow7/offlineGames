[English](IPConsiderations.md) | [简体中文](IPConsiderations.zh-Hans.md)

# IP Considerations

This document analyzes the intellectual property landscape for each game in the Offline Games collection. It covers game mechanic legality, trade dress avoidance, naming strategy, and asset originality requirements.

---

## Table of Contents

1. [General Principles](#general-principles)
2. [Block Puzzle (Tetris-Style)](#block-puzzle-tetris-style)
3. [Snake](#snake)
4. [Breakout (Brick Breaker)](#breakout-brick-breaker)
5. [Minesweeper](#minesweeper)
6. [Memory Match (Original)](#memory-match-original)
7. [Reaction Tap (Original)](#reaction-tap-original)
8. [Art, Sound, and Music](#art-sound-and-music)
9. [App Store Name and Icon](#app-store-name-and-icon)
10. [Summary Matrix](#summary-matrix)

---

## General Principles

### Game Mechanics Are Not Copyrightable

Under U.S. copyright law and broadly in most jurisdictions, **game mechanics and rules are not copyrightable**. Copyright protects creative expression (art, code, music, story), not functional ideas or systems. This has been affirmed in multiple court cases, including *Tetris Holding, LLC v. Xio Interactive, Inc.* (2012).

However, there are important nuances:

- **Trade dress** (the overall visual look and feel) can be protected if it is distinctive and non-functional.
- **Trademarks** (names, logos, distinctive terms) are protected and must be avoided.
- **Specific creative expression** -- the exact arrangement of visual elements, specific art assets, specific code -- is copyrightable.
- **Patents** on specific game mechanics can exist (though most classic game mechanic patents have expired).

### Our Strategy

1. Implement **generic gameplay mechanics** that are in the public domain.
2. Use **original names** that do not reference any trademarked game titles.
3. Use **original visual designs** that are clearly differentiated from protected trade dress.
4. Create or license **all art, sound, and music** assets.
5. Avoid any **distinctive terminology** associated with specific commercial games.

---

## Block Puzzle (Tetris-Style)

### Risk Assessment: MODERATE -- Requires Careful Differentiation

The Tetris Company is notoriously aggressive in protecting their IP. While the *mechanic* of falling-block puzzle games is generic, the Tetris Company has successfully argued trade dress protection for the specific look and feel of Tetris.

### What Is Protected

- The name "Tetris" and all variations (trademark)
- The term "Tetrimino" (trademark -- a portmanteau of "tetromino" + the Tetris brand)
- The specific trade dress: 10x20 grid, 7 specific tetromino shapes in specific colors, ghost piece, hold piece, the particular visual arrangement
- The *Tetris Holding v. Xio Interactive* ruling found that the cloned game's visual expression was too similar

### Our Differentiation Strategy

| Aspect | Tetris | Our "Block Puzzle" |
|---|---|---|
| **Name** | Tetris | "Block Puzzle" (generic term) |
| **Grid size** | 10 wide x 20 tall | **12 wide x 24 tall** |
| **Piece types** | 7 tetrominoes (4-cell pieces) | **Custom pentomino-style pieces** (5-cell pieces) |
| **Piece names** | I, O, T, S, Z, J, L / "Tetriminos" | Generic names (no letter-based naming) |
| **Color scheme** | Specific trademarked palette | **Original color palette** using the app's Liquid Glass theme |
| **Hold piece** | Standard Tetris feature | Not implemented (or original variation) |
| **Ghost piece** | Specific Tetris visual | Original drop preview implementation |
| **Scoring** | Specific Tetris scoring rules | **Original scoring algorithm** |

### Code Implementation

From `BlockPuzzleState.swift`:

```swift
public struct BlockPuzzleState: GameState, Equatable, Sendable {
    /// Grid dimensions (wider than standard to differentiate).
    public let gridWidth: Int    // Default: 12 (not 10)
    public let gridHeight: Int   // Default: 24 (not 20)
    // ...
}
```

Pieces are defined as relative cell offsets, using 5-cell pentomino shapes:

```swift
public struct Piece: Equatable, Sendable {
    public let cells: [(dx: Int, dy: Int)]  // Pentomino-style (5 cells, not 4)
    public let colorIndex: Int
    // ...
}
```

### What to Avoid

- Never use the word "Tetris," "Tetrimino," or "Tetromino" anywhere in the app (code, UI, metadata, marketing).
- Never use the standard 10x20 grid dimensions.
- Never replicate the exact 7 standard tetromino shapes as the primary piece set.
- Never copy the Tetris color palette.
- Never reference "Tetris-like" or "Tetris-style" in the App Store listing.

---

## Snake

### Risk Assessment: LOW

Snake is one of the most generic game concepts in existence. The core mechanic (a growing line that must avoid itself and walls) predates any specific commercial version and has been independently implemented countless times since the 1970s.

### What Is Protected

- The name "Snake" as a game is **not trademarked** in the context of video games -- it is a common English word.
- Nokia's specific implementation (the pixelated look on Nokia 3310, the specific name "Snake" in that context) has trade dress elements, but the underlying game concept is public domain.
- Specific art assets, sounds, and code from any commercial Snake game are copyrighted.

### Our Approach

| Aspect | Strategy |
|---|---|
| **Name** | "Snake" -- generic term, freely usable |
| **Gameplay** | Standard snake mechanics (public domain since the 1970s) |
| **Visual style** | Original iOS 26 Liquid Glass aesthetic -- clearly distinct from any retro pixel art or Nokia styling |
| **Art** | Original vector/Metal-rendered graphics |
| **Sound** | Original sound effects |
| **References** | No references to Nokia, no retro pixel aesthetic mimicking Nokia phones |

### What to Avoid

- Do not include Nokia branding, logos, or references.
- Do not replicate the exact green-on-dark pixel aesthetic of Nokia Snake.
- Do not market as "Nokia Snake" or "Classic Nokia Game."
- Do not use the specific Nokia Snake sound effects.

---

## Breakout (Brick Breaker)

### Risk Assessment: LOW

The brick-breaking mechanic (paddle, ball, breakable bricks) originated with Atari's "Breakout" (1976) and has been in the public domain as a game mechanic for decades. The term "Breakout" itself is a common English word. Hundreds of brick-breaker games exist on every platform.

### What Is Protected

- Specific Atari/Taito "Arkanoid" branding and art assets
- The name "Arkanoid" (trademark of Taito)
- Specific level designs from commercial games

### Our Approach

| Aspect | Strategy |
|---|---|
| **Name** | "Breakout" (generic English word) or "Brick Breaker" |
| **Gameplay** | Standard paddle-ball-bricks mechanics |
| **Visual style** | Original Liquid Glass design with Metal rendering |
| **Level design** | Original brick layouts |
| **Power-ups** | Generic power-up concepts (wider paddle, multi-ball) |

### What to Avoid

- Do not use "Arkanoid" or any Taito branding.
- Do not copy specific level layouts from commercial games.
- Do not replicate specific power-up designs (visual or mechanical) unique to Arkanoid.

---

## Minesweeper

### Risk Assessment: VERY LOW

Minesweeper is a logic puzzle game that predates Microsoft's implementation (which appeared in Windows 3.1, 1992). The concept of revealing cells on a grid while avoiding hidden mines is a generic game mechanic.

### What Is Protected

- Microsoft's specific implementation (the exact Windows Minesweeper visual design with the smiley face, specific flag icon, specific font, specific grid rendering)
- The name "Minesweeper" is **not trademarked** by Microsoft for games -- it is a common English word (a naval vessel that clears mines)

### Our Approach

| Aspect | Strategy |
|---|---|
| **Name** | "Minesweeper" -- generic term |
| **Gameplay** | Standard reveal-cells, flag-mines mechanics |
| **Visual style** | Original iOS 26 Liquid Glass design -- distinctly different from Windows Minesweeper |
| **Grid** | Customizable sizes, not tied to specific "Beginner/Intermediate/Expert" dimensions |
| **UI elements** | No smiley face button, no Windows-style flag icon |

### What to Avoid

- Do not replicate the Windows Minesweeper visual design (gray raised cells, specific smiley face, sunglasses smiley for wins).
- Do not copy Microsoft's exact difficulty presets if labeling them identically.

---

## Memory Match (Original)

### Risk Assessment: NONE

Memory Match (also known as Concentration) is a traditional card-matching game that has existed for centuries as a physical card game. There is no IP concern with the game mechanic.

### Our Implementation

- **Fully original** game design.
- **Original card art** -- custom symbols using SF Symbols and original graphics.
- **Original name** -- "Memory Match" is a generic descriptive term.
- No reference to any specific commercial memory game.
- Custom grid sizes and difficulty levels.

---

## Reaction Tap (Original)

### Risk Assessment: NONE

Reaction Tap is an **entirely original game** concept created for this app. It tests reaction speed by requiring the player to tap targets that appear on screen.

### Our Implementation

- **Fully original** concept, design, and implementation.
- **Original name** -- "Reaction Tap" is a descriptive, original title.
- No reference to any existing game.
- Original scoring algorithm based on reaction time.

---

## Art, Sound, and Music

### Absolute Requirements

All creative assets in the app **must** be one of the following:

1. **Original creations** made specifically for this project.
2. **Licensed assets** with a license that permits commercial use in mobile apps.
3. **Public domain assets** verified to be free of all copyright restrictions.
4. **System-provided assets** (SF Symbols -- governed by Apple's license for use in Apple platform apps).

### Asset Audit Checklist

For every asset in the project:

- [ ] Source is documented (original, licensed, or system-provided)
- [ ] License permits commercial use in a paid or free app
- [ ] License permits modification (if the asset has been altered)
- [ ] No attribution requirements that are unfulfilled (or attribution is provided)
- [ ] Asset does not visually or audibly resemble a copyrighted asset from another game

### SF Symbols Usage

SF Symbols are used for game icons in the catalog (`GameMetadata.iconName`). Apple's SF Symbols license permits use within apps running on Apple platforms. This is safe for our use case.

### Sound Effects

All sound effects must be original recordings or synthesized audio. Do not use:
- Sound effects from classic games (the Tetris theme, Nokia Snake beep, Windows Minesweeper click)
- Unlicensed sound packs
- YouTube audio rips

### Music

If background music is added, it must be original compositions or properly licensed royalty-free music with documentation of the license.

---

## App Store Name and Icon

### App Store Name

The app name is "Offline Games" -- a purely descriptive, generic term. It does not reference any trademarked game title.

**Do NOT** include trademarked game names in:
- The app title
- The subtitle
- The keywords field
- The description (do not say "like Tetris" or "Tetris-style")

**Acceptable phrasing in the description:**
- "Block puzzle game" (generic)
- "Snake game" (generic)
- "Brick breaker" (generic)
- "Logic puzzle" (generic)

**Unacceptable phrasing:**
- "Tetris clone"
- "Like Tetris"
- "Tetris-style block puzzle"
- "Nokia Snake"
- "Arkanoid-like"

### App Icon

The app icon must be an original design that does not resemble any trademarked game's icon. Do not use:
- Tetromino shapes (L, T, S, Z shapes commonly associated with Tetris)
- A pixelated snake reminiscent of Nokia
- Any color scheme that closely mimics a specific game's branding

---

## Summary Matrix

| Game | Mechanic Risk | Name Risk | Visual Risk | Strategy |
|---|---|---|---|---|
| Block Puzzle | Moderate | None ("Block Puzzle" is generic) | Moderate (avoid Tetris trade dress) | Custom pentomino pieces, 12x24 grid, original colors |
| Snake | None | None ("Snake" is generic) | Low (avoid Nokia look) | Original Liquid Glass visual style, no Nokia references |
| Breakout | None | None ("Breakout" is generic) | Low (avoid Arkanoid look) | Original design, original levels |
| Minesweeper | None | None ("Minesweeper" is generic) | Low (avoid Windows look) | Original Liquid Glass design, no smiley face |
| Memory Match | None | None (original name) | None (fully original) | Fully original |
| Reaction Tap | None | None (original name) | None (fully original) | Fully original |

### Key Takeaways

1. **Block Puzzle requires the most care.** The Tetris Company actively enforces IP. Our differentiation (pentomino pieces, 12x24 grid, no Tetris terminology) provides meaningful distance.
2. **Snake, Breakout, and Minesweeper** are safe with basic precautions (original visuals, no brand references).
3. **Memory Match and Reaction Tap** are fully original with zero IP concerns.
4. **All assets must be original or properly licensed** -- this is non-negotiable.
5. **App Store metadata must never reference trademarked game names.**
