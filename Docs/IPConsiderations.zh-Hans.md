[English](IPConsiderations.md) | [简体中文](IPConsiderations.zh-Hans.md)

# IP Considerations

本文档分析了 Offline Games 集合中每个游戏的知识产权（IP）情况。内容涵盖了游戏机制的合法性、规避商业外观（Trade Dress）、命名策略以及素材原创性要求。

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

根据美国版权法以及大多数司法管辖区的广泛规定，**游戏机制和规则不受版权保护**。版权保护的是创意表达（艺术、代码、音乐、故事），而非功能性的想法或系统。这一点已在多个法院案件中得到确认，包括 *Tetris Holding, LLC v. Xio Interactive, Inc.* (2012)。

然而，存在一些重要的细微差别：

- **商业外观**（整体视觉外观和感觉）如果具有辨识度且非功能性，则可以受到保护。
- **商标**（名称、Logo、独特术语）受保护，必须予以避开。
- **特定的创意表达** —— 视觉元素的精确排列、特定的艺术资产、特定的代码 —— 是受版权保护的。
- 针对特定游戏机制的**专利**可能存在（尽管大多数经典游戏机制专利已经过期）。

### Our Strategy

1. 实现属于公有领域的**通用游戏机制**。
2. 使用不引用任何注册商标游戏名称的**原创名称**。
3. 使用与受保护的商业外观有明显区别的**原创视觉设计**。
4. 创作或获得**所有艺术、声音和音乐**素材的授权。
5. 避免使用与特定商业游戏相关的任何**独特术语**。

---

## Block Puzzle (Tetris-Style)

### Risk Assessment: MODERATE -- Requires Careful Differentiation

Tetris Company（俄罗斯方块公司）在保护其 IP 方面是出了名的强势。虽然下落方块拼图游戏的*机制*是通用的，但 Tetris Company 已成功争取到了对《俄罗斯方块》特定外观和感觉的商业外观保护。

### What Is Protected

- 名称 "Tetris" 及其所有变体（商标）
- 术语 "Tetrimino"（商标 —— "tetromino" + Tetris 品牌的合成词）
- 特定的商业外观：10x20 的网格、7 种特定颜色的特定四连块形状、幽灵方块、暂存方块、特定的视觉布局
- *Tetris Holding v. Xio Interactive* 的裁决发现，克隆游戏的视觉表达过于相似

### Our Differentiation Strategy

| 方面 | 俄罗斯方块 (Tetris) | 我们的“方块拼图” (Block Puzzle) |
|---|---|---|
| **名称** | Tetris | "Block Puzzle"（通用术语） |
| **网格尺寸** | 10 宽 x 20 高 | **12 宽 x 24 高** |
| **方块类型** | 7 种四连块 (tetrominoes) | **自定义五连块风格方块 (pentomino-style)** |
| **方块名称** | I, O, T, S, Z, J, L / "Tetriminos" | 通用名称（不使用字母命名） |
| **配色方案** | 特定的商标调色板 | 使用应用的 Liquid Glass 主题的**原创调色板** |
| **暂存方块** | 标准俄罗斯方块功能 | 未实现（或使用原创变体） |
| **幽灵方块** | 特定的俄罗斯方块视觉效果 | 原创的下落预览实现 |
| **计分** | 特定的俄罗斯方块计分规则 | **原创计分算法** |

### Code Implementation

摘自 `BlockPuzzleState.swift`：

```swift
public struct BlockPuzzleState: GameState, Equatable, Sendable {
    /// 网格尺寸（比标准更宽以示区别）。
    public let gridWidth: Int    // 默认：12 (不是 10)
    public let gridHeight: Int   // 默认：24 (不是 20)
    // ...
}
```

方块定义为单元格的相对偏移，使用 5 单元格的五连块形状：

```swift
public struct Piece: Equatable, Sendable {
    public let cells: [(dx: Int, dy: Int)]  // 五连块风格（5 个单元格，而非 4 个）
    public let colorIndex: Int
    // ...
}
```

### What to Avoid

- 严禁在应用任何位置（代码、UI、元数据、营销资料）使用 "Tetris"、"Tetrimino" 或 "Tetromino" 单词。
- 严禁使用标准的 10x20 网格尺寸。
- 严禁完全复制标准的 7 种四连块作为主要方块集。
- 严禁复制《俄罗斯方块》的调色板。
- 严禁在 App Store 列表页中提及 "Tetris-like"（类俄罗斯方块）或 "Tetris-style"（俄罗斯方块风格）。

---

## Snake

### Risk Assessment: LOW

贪吃蛇（Snake）是现存最通用的游戏概念之一。其核心机制（一条不断增长的线必须避开自身和墙壁）早于任何特定的商业版本，自 20 世纪 70 年代以来已被独立实现过无数次。

### What Is Protected

- "Snake" 作为游戏名称在电子游戏语境下**未被注册商标** —— 它是一个通用的英文单词。
- 诺基亚（Nokia）的特定实现（诺基亚 3310 上的像素外观、在该语境下的特定名称 "Snake"）具有商业外观元素，但底层的游戏概念属于公有领域。
- 任何商业版贪吃蛇游戏的特定艺术资产、声音和代码均受版权保护。

### Our Approach

| 方面 | 策略 |
|---|---|
| **名称** | "Snake" —— 通用术语，可自由使用 |
| **玩法** | 标准贪吃蛇机制（自 20 世纪 70 年代起属于公有领域） |
| **视觉风格** | 原创的 iOS 26 Liquid Glass 美学 —— 与任何复古像素艺术或诺基亚风格有明显区别 |
| **艺术素材** | 原创的矢量/Metal 渲染图形 |
| **声音** | 原创音效 |
| **引用** | 不提及诺基亚，不使用模仿诺基亚手机的复古像素美学 |

### What to Avoid

- 不要包含诺基亚的品牌、Logo 或引用。
- 不要复制诺基亚贪吃蛇那种特定的深色背景上的绿色像素美学。
- 不要以 "Nokia Snake" 或 "Classic Nokia Game" 进行营销。
- 不要使用诺基亚贪吃蛇特定的音效。

---

## Breakout (Brick Breaker)

### Risk Assessment: LOW

弹球消砖块机制（挡板、球、可破碎的砖块）起源于雅达利（Atari）的《Breakout》（1976 年），作为一种游戏机制已进入公有领域数十年。"Breakout" 一词本身也是一个通用的英文单词。每个平台上都有数百种弹球消砖块游戏。

### What Is Protected

- 特定的雅达利（Atari）/太东（Taito）《Arkanoid》（快打砖块）品牌和艺术资产
- 名称 "Arkanoid"（Taito 的商标）
- 商业游戏中的特定关卡设计

### Our Approach

| 方面 | 策略 |
|---|---|
| **名称** | "Breakout"（通用英文单词）或 "Brick Breaker" |
| **玩法** | 标准挡板-球-砖块机制 |
| **视觉风格** | 采用 Metal 渲染的原创 Liquid Glass 设计 |
| **关卡设计** | 原创砖块布局 |
| **增益道具** | 通用的增益概念（加宽挡板、多球模式） |

### What to Avoid

- 不要使用 "Arkanoid" 或任何太东（Taito）品牌。
- 不要复制商业游戏中的特定关卡布局。
- 不要复制《Arkanoid》中特有的增益道具设计（无论是视觉还是机制）。

---

## Minesweeper

### Risk Assessment: VERY LOW

扫雷是一款逻辑益智游戏，早于微软的实现版本（出现在 1992 年的 Windows 3.1 中）。在网格上揭开单元格并避开隐藏地雷的概念是一种通用的游戏机制。

### What Is Protected

- 微软的特定实现（带有笑脸的精确 Windows 扫雷视觉设计、特定的旗帜图标、特定的字体、特定的网格渲染）
- "Minesweeper" 这一名称**未被微软注册为游戏商标** —— 它是一个通用的英文单词（指清除地雷的海军舰艇）。

### Our Approach

| 方面 | 策略 |
|---|---|
| **名称** | "Minesweeper" —— 通用术语 |
| **玩法** | 标准揭开单元格、标记地雷机制 |
| **视觉风格** | 原创 iOS 26 Liquid Glass 设计 —— 与 Windows 扫雷有明显区别 |
| **网格** | 可自定义尺寸，不局限于特定的“初级/中级/高级”维度 |
| **UI 元素** | 没有笑脸按钮，没有 Windows 风格的旗帜图标 |

### What to Avoid

- 不要复制 Windows 扫雷的视觉设计（灰色凸起单元格、特定的笑脸、胜利时的墨镜笑脸）。
- 如果标签名称完全相同，不要复制微软精确的难度预设。

---

## Memory Match (Original)

### Risk Assessment: NONE

记忆配对（Memory Match，也称为 Concentration）是一种传统的卡片匹配游戏，作为实体卡牌游戏已存在数世纪。该游戏机制不存在 IP 问题。

### Our Implementation

- **完全原创**的游戏设计。
- **原创卡片艺术** —— 使用 SF Symbols 和原创图形的自定义符号。
- **原创名称** —— "Memory Match" 是一个通用的描述性术语。
- 不引用任何特定的商业记忆游戏。
- 自定义网格尺寸和难度等级。

---

## Reaction Tap (Original)

### Risk Assessment: NONE

反应点击（Reaction Tap）是为本应用开发的**完全原创的游戏**概念。它通过要求玩家点击屏幕上出现的目标来测试反应速度。

### Our Implementation

- **完全原创**的概念、设计和实现。
- **原创名称** —— "Reaction Tap" 是一个描述性的原创标题。
- 不引用任何现有游戏。
- 基于反应时间的原创计分算法。

---

## Art, Sound, and Music

### Absolute Requirements

应用中的所有创意素材**必须**符合以下条件之一：

1. 专门为此项目创作的**原创作品**。
2. 获得许可的**授权素材**，且许可允许在移动应用中进行商业使用。
3. 经核实不含任何版权限制的**公有领域素材**。
4. **系统提供的素材**（SF Symbols —— 受 Apple 在 Apple 平台应用中使用许可的约束）。

### Asset Audit Checklist

对于项目中的每一个素材：

- [ ] 来源已记录（原创、授权或系统提供）
- [ ] 许可允许在付费或免费应用中进行商业使用
- [ ] 许可允许修改（如果素材已被更改）
- [ ] 没有未履行的署名要求（或已提供署名）
- [ ] 素材在视觉或听觉上不与另一个受版权保护的游戏素材雷同

### SF Symbols Usage

SF Symbols 用于目录中的游戏图标（`GameMetadata.iconName`）。Apple 的 SF Symbols 许可允许在运行于 Apple 平台的应用内使用。这对于我们的用例是安全的。

### Sound Effects

所有音效必须是原创录制或合成的音频。严禁使用：
- 经典游戏的音效（俄罗斯方块主题曲、诺基亚贪吃蛇蜂鸣音、Windows 扫雷点击声）
- 未经授权的音效包
- 从 YouTube 提取的音频

### Music

如果添加背景音乐，必须是原创作品或拥有完整授权文档的版税免费音乐（Royalty-free music）。

---

## App Store Name and Icon

### App Store Name

应用名称为 "Offline Games" —— 这是一个纯描述性的通用术语。它没有引用任何注册商标的游戏标题。

**严禁**在以下位置包含注册商标的游戏名称：
- 应用标题
- 副标题
- 关键词字段
- 描述（不要说 "like Tetris" 或 "Tetris-style"）

**描述中可接受的表述：**
- "Block puzzle game"（方块拼图游戏，通用）
- "Snake game"（贪吃蛇游戏，通用）
- "Brick breaker"（打砖块，通用）
- "Logic puzzle"（逻辑益智，通用）

**不可接受的表述：**
- "Tetris clone"（俄罗斯方块克隆版）
- "Like Tetris"（像俄罗斯方块）
- "Tetris-style block puzzle"（俄罗斯方块风格方块拼图）
- "Nokia Snake"（诺基亚贪吃蛇）
- "Arkanoid-like"（类快打砖块）

### App Icon

应用图标必须是原创设计，不得与任何注册商标的游戏图标雷同。严禁使用：
- 四连块形状（通常与俄罗斯方块相关的 L、T、S、Z 形状）
- 令人联想到诺基亚的像素化蛇
- 任何紧密模仿特定游戏品牌形象的配色方案

---

## Summary Matrix

| 游戏 | 机制风险 | 名称风险 | 视觉风险 | 策略 |
|---|---|---|---|---|
| Block Puzzle | 中等 | 无 ("Block Puzzle" 为通用词) | 中等 (避开俄罗斯方块商业外观) | 自定义五连块、12x24 网格、原创配色 |
| Snake | 无 | 无 ("Snake" 为通用词) | 低 (避开诺基亚外观) | 原创 Liquid Glass 视觉风格，无诺基亚引用 |
| Breakout | 无 | 无 ("Breakout" 为通用词) | 低 (避开 Arkanoid 外观) | 原创设计，原创关卡 |
| Minesweeper | 无 | 无 ("Minesweeper" 为通用词) | 低 (避开 Windows 外观) | 原创 Liquid Glass 设计，无笑脸 |
| Memory Match | 无 | 无 (原创名称) | 无 (完全原创) | 完全原创 |
| Reaction Tap | 无 | 无 (原创名称) | 无 (完全原创) | 完全原创 |

### Key Takeaways

1. **方块拼图（Block Puzzle）需要最谨慎对待。** Tetris Company 积极维护其 IP。我们的差异化（五连块、12x24 网格、不使用俄罗斯方块术语）提供了足够的安全距离。
2. **贪吃蛇、弹球消砖块和扫雷**在采取基本预防措施（原创视觉、无品牌引用）的情况下是安全的。
3. **记忆配对和反应点击**是完全原创的，没有任何 IP 担忧。
4. **所有素材必须是原创或经过正当授权的** —— 这是不可逾越的底线。
5. **App Store 元数据绝不能引用注册商标的游戏名称。**
