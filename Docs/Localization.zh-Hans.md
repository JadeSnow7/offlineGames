[English](Localization.md) | [简体中文](Localization.zh-Hans.md)

# Localization Guide

本文档描述了 Offline Games 应用的本地化方法，包括如何添加新语言区域、命名规范、测试策略以及无障碍功能考量。

---

## Table of Contents

1. [概述](#overview)
2. [String Catalog 方法](#string-catalog-approach)
3. [如何添加新语言区域](#how-to-add-a-new-locale)
4. [本地化键值的命名规范](#naming-conventions-for-localization-keys)
5. [字符串插值与复数](#string-interpolation-and-plurals)
6. [测试本地化](#testing-localization)
7. [RTL 语言考量](#rtl-language-considerations)
8. [无障碍与 VoiceOver 字符串](#accessibility-and-voiceover-strings)
9. [本地化清单](#localization-checklist)

---

## Overview

该项目使用 Apple 的 **String Catalog** (`.xcstrings`) 格式，该格式在 Xcode 15 中引入，并在 Xcode 26 中得到全面支持。String Catalog 提供：

- 每个 Target 一个文件，包含所有语言区域的所有翻译。
- 自动从 Swift 代码中提取 `String(localized:)` 和 `Text()` 字符串。
- 内置对复数规则、字符串插值和设备变体的支持。
- Xcode 中为翻译人员提供的可视化编辑器。

应用的基准开发语言为 **英语 (en)**。

---

## String Catalog Approach

### File Location

每个包含面向用户字符串的包都有自己的字符串目录：

```
Packages/GameUI/Sources/GameUI/Resources/Localizable.xcstrings        # 共享 UI 字符串
Packages/BlockPuzzle/Sources/BlockPuzzle/Resources/Localizable.xcstrings
Packages/SnakeGame/Sources/SnakeGame/Resources/Localizable.xcstrings
Packages/BreakoutGame/Sources/BreakoutGame/Resources/Localizable.xcstrings
Packages/MinesweeperGame/Sources/MinesweeperGame/Resources/Localizable.xcstrings
Packages/MemoryMatch/Sources/MemoryMatch/Resources/Localizable.xcstrings
Packages/ReactionTap/Sources/ReactionTap/Resources/Localizable.xcstrings
App/Resources/Localizable.xcstrings                                     # 应用级字符串
```

### Using Localized Strings in Swift

SwiftUI 的 `Text` 视图会自动查找字符串键：

```swift
// 通过 string catalog 自动本地化
Text("game.score.label")

// 使用插值
Text("game.score.value \(score)")

// 在非 Text 上下文中使用 String(localized:)
let title = String(localized: "game.pause.title")
```

### String Catalog File Format

`.xcstrings` 文件是 JSON 格式。Xcode 提供可视化编辑器，但底层格式如下：

```json
{
  "sourceLanguage": "en",
  "strings": {
    "game.score.label": {
      "localizations": {
        "en": {
          "stringUnit": {
            "state": "translated",
            "value": "Score"
          }
        },
        "ja": {
          "stringUnit": {
            "state": "translated",
            "value": "スコア"
          }
        }
      }
    }
  }
}
```

---

## How to Add a New Locale

### Step 1: Add the language to the project

1. 打开 Xcode 项目。
2. 在导航器中选择项目（而非 target）。
3. 在 **Info > Localizations** 下，点击 `+` 按钮。
4. 选择语言（例如：法语、日语、简体中文）。
5. Xcode 将把该语言添加到所有 `.xcstrings` 文件中。

### Step 2: Translate strings

1. 在 Xcode 中打开任意 `.xcstrings` 文件。
2. 在侧边栏选择新语言。
3. 为每个字符串键输入翻译后的值。
4. 完成后将每个字符串标记为“已翻译”（绿色对勾）。
5. 标记为“新建”（蓝色）或“需审核”（黄色）的字符串将回退到基准语言。

### Step 3: Handle plurals (if needed)

某些字符串需要复数变体。当 Xcode 检测到插值的整数值时，会自动处理：

```swift
Text("game.lines.cleared \(linesCleared)")
```

在字符串目录中，展开此键以提供复数形式：

| 复数类别 | 英语 | 日语 |
|---|---|---|
| zero | "No lines cleared" | "ラインクリアなし" |
| one | "1 line cleared" | "1ラインクリア" |
| other | "%lld lines cleared" | "%lldラインクリア" |

### Step 4: Test the new locale

参见下文的 [测试本地化](#testing-localization)。

### Currently Supported Locales

| 代码 | 语言 | 状态 |
|---|---|---|
| `en` | 英语 | 基准语言 |
| `ja` | 日语 | 计划中 |
| `zh-Hans` | 简体中文 | 计划中 |
| `es` | 西班牙语 | 计划中 |
| `de` | 德语 | 计划中 |
| `fr` | 法语 | 计划中 |
| `ar` | 阿拉伯语 (RTL) | 计划中 |

---

## Naming Conventions for Localization Keys

### Key Format

使用点分隔的层级结构：`<module>.<screen>.<element>`。

```
game.score.label              # "Score"
game.score.value              # "%lld" (插值)
game.pause.title              # "Paused"
game.pause.resume             # "Resume"
game.pause.restart            # "Restart"
game.over.title               # "Game Over"
game.over.newHighScore        # "New High Score!"
game.over.playAgain           # "Play Again"

catalog.title                 # "Games"
catalog.category.action       # "Action"
catalog.category.puzzle       # "Puzzle"
catalog.category.classic      # "Classic"
catalog.category.reflex       # "Reflex"

settings.title                # "Settings"
settings.sound.toggle         # "Sound Effects"
settings.haptics.toggle       # "Haptics"
settings.theme.title          # "Theme"

blockPuzzle.name              # "Block Puzzle"
blockPuzzle.description       # "Arrange falling pieces to clear lines."
snake.name                    # "Snake"
snake.description             # "Guide the snake to eat food and grow."
```

### Rules

1. **最后一段始终使用 camelCase**：使用 `game.over.playAgain`，而不是 `game.over.play_again`。
2. **游戏特定字符串以模块名为前缀**：`blockPuzzle.name`，`snake.description`。
3. **共享字符串使用通用前缀**：`game.`，`catalog.`，`settings.`。
4. **切勿使用英文文本作为键**。使用语义化的键（如 `game.over.title`）代替 `"Game Over"`。这允许在不破坏翻译的情况下更改英文文本。
5. **键应简短但具有描述性**。目标是最多 3-4 个分段。
6. **当含义模糊时，在字符串目录的注释字段中记录上下文**。

---

## String Interpolation and Plurals

### Simple Interpolation

```swift
// Swift 代码
Text("game.score.value \(score)")

// "en" 的字符串目录条目：
// "Score: %lld"

// "ja" 的字符串目录条目：
// "スコア: %lld"
```

### Multiple Interpolations

```swift
Text("game.stats.summary \(level) \(score)")

// "en": "Level %lld - Score %lld"
// 翻译人员可以重新排序："ja": "スコア %2$lld - レベル %1$lld"
```

### Plural Variations

对于包含计数的字符串，Xcode 会根据目标语言的 CLDR 复数规则自动提供复数类别：

- **英语**：one, other
- **日语**：other（日语没有语法上的复数）
- **阿拉伯语**：zero, one, two, few, many, other
- **法语**：one, many, other

### Device Variations

String catalogs 支持设备特定的变体（iPhone vs. iPad）。请谨慎使用：

```
"game.controls.hint" (iPhone): "Tap to play"
"game.controls.hint" (iPad):   "Tap or use keyboard to play"
```

---

## Testing Localization

### Method 1: Xcode Scheme Override

1. Edit Scheme > Run > Options。
2. 将 **App Language** 设置为目标语言区域。
3. 将 **App Region** 设置为对应的地区。
4. 运行应用。所有字符串将使用选定的语言区域。

### Method 2: Double-Length Pseudolanguage

测试长翻译导致的布局问题：

1. Edit Scheme > Run > Options。
2. 将 **App Language** 设置为 "Double Length Pseudolanguage"。
3. 所有字符串都会翻倍（例如，“Score” 变成 “Score Score”）。
4. 检查所有 UI 元素是否仍然自适应。

### Method 3: Accented Pseudolanguage

测试硬编码字符串（绕过本地化的字符串）：

1. Edit Scheme > Run > Options。
2. 将 **App Language** 设置为 "Accented Pseudolanguage"。
3. 本地化后的字符串会带有重音符号："[Score]" 变成 "[Scoooree]"。
4. 任何*不带*重音出现的文本都是硬编码的，需要本地化。

### Method 4: Right-to-Left Pseudolanguage

无需实际的 RTL 翻译即可测试 RTL 布局：

1. Edit Scheme > Run > Options。
2. 将 **App Language** 设置为 "Right-to-Left Pseudolanguage"。
3. 整个 UI 将翻转为 RTL。

### Method 5: Preview in Xcode

在 SwiftUI 预览中使用显式语言区域：

```swift
#Preview {
    MyGameView()
        .environment(\.locale, Locale(identifier: "ja"))
}
```

### Method 6: Automated Testing

```swift
@Test func allStringsHaveTranslations() {
    let bundle = Bundle.module
    let keys = ["game.score.label", "game.pause.title", "game.over.title"]
    for key in keys {
        let localized = bundle.localizedString(forKey: key, value: nil, table: nil)
        #expect(localized != key, "Missing translation for: \(key)")
    }
}
```

---

## RTL Language Considerations

支持 RTL 语言（阿拉伯语、希伯来语）时，请确保以下几点：

### Layout Flipping

在使用标准布局容器时，SwiftUI 会自动为 RTL 语言翻转布局：

```swift
// 在 RTL 模式下自动翻转
HStack {
    Image(systemName: "star.fill")
    Text("game.score.label")
    Spacer()
    Text("\(score)")
}
// 在 LTR 模式下: [star] Score         100
// 在 RTL 模式下: 100         نتيجة [star]
```

### Leading/Trailing vs. Left/Right

始终使用 `.leading` 和 `.trailing`，而不是 `.left` 和 `.right`：

```swift
// 正确：自适应 RTL
.padding(.leading, 16)
.frame(alignment: .trailing)

// 错误：不自适应 RTL
.padding(.left, 16)
.frame(alignment: .right)
```

### Game Board Direction

游戏棋盘（网格）通常**不应**在 RTL 模式下翻转，因为游戏逻辑依赖于绝对坐标。只有 UI 装饰（按钮、标签、导航）应当翻转：

```swift
// 防止游戏棋盘翻转
GameBoardView()
    .environment(\.layoutDirection, .leftToRight)  // 固定为 LTR

// 让 HUD 自然翻转
HUDOverlayView()
    // 继承系统布局方向
```

### Number Formatting

对数字使用 `formatted()` 以遵循语言区域习惯：

```swift
Text(score.formatted())  // 英语中为 "1,234"，德语中为 "1.234"，阿拉伯语中为 "١٬٢٣٤"
```

### Text Alignment

使用 `.multilineTextAlignment(.leading)` 而不是 `.left`：

```swift
Text(longDescription)
    .multilineTextAlignment(.leading)  // 自适应 RTL
```

---

## Accessibility and VoiceOver Strings

### Separate Accessibility Labels

VoiceOver 标签应描述元素的*属性*或*功能*，而不仅仅是重复视觉文本：

```swift
GlassButton("game.pause.resume") {
    // ...
}
.accessibilityLabel(Text("accessibility.pause.resume"))
// 视觉上: "Resume"
// VoiceOver: "Resume game"
```

### Localization Keys for Accessibility

为 VoiceOver 特有的字符串使用 `accessibility.` 前缀：

```
accessibility.game.board          # "Game board, 12 columns by 24 rows"
accessibility.game.score          # "Current score: %lld"
accessibility.game.piece.current  # "Current piece: L-shape at column %lld"
accessibility.catalog.game        # "%@ game. %@"  (名称, 描述)
accessibility.button.play         # "Start game"
accessibility.button.pause        # "Pause game"
```

### Accessibility Hints

提示描述用户激活元素后*将发生什么*：

```swift
GlassButton("game.over.playAgain") { ... }
    .accessibilityLabel(Text("accessibility.button.playAgain.label"))
    .accessibilityHint(Text("accessibility.button.playAgain.hint"))
// 标签: "Play Again"
// 提示: "Starts a new game"
```

### Dynamic Type

所有文本都应支持动态类型。使用 `AppTheme` 字体（基于系统文本样式）可确保这一点：

```swift
Text("game.score.label")
    .font(AppTheme.bodyFont)  // 随动态类型缩放
```

除非游戏渲染绝对必要，否则避免使用固定字体大小。

### VoiceOver for Game State Changes

当发生重要状态变化时发布无障碍通知：

```swift
if newState.isGameOver {
    UIAccessibility.post(
        notification: .announcement,
        argument: String(localized: "accessibility.game.over.announcement \(newState.score)")
    )
}
```

---

## Localization Checklist

针对每个新语言区域：

- [ ] 已在 Xcode 项目设置中添加语言
- [ ] 所有字符串目录键值已翻译
- [ ] 已为该语言配置复数规则
- [ ] 所有无障碍字符串已翻译
- [ ] 已使用该语言区域测试 UI —— 无截断或溢出
- [ ] 已测试双倍长度伪语言以验证布局
- [ ] 已测试 RTL 布局（如适用）
- [ ] 已验证数字和日期格式
- [ ] 已翻译 App Store 元数据（名称、描述、关键词）
- [ ] 已生成该语言区域的屏幕截图

针对每个新的面向用户的字符串：

- [ ] 使用语义化键（而非英文文本）
- [ ] 键遵循命名规范 (`module.screen.element`)
- [ ] 已添加到相应的 `.xcstrings` 文件
- [ ] 如果与视觉文本不同，已提供无障碍标签
- [ ] 已通过 VoiceOver 测试
- [ ] 已通过双倍长度伪语言测试布局
