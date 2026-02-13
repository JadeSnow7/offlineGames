# Localization Guide

This document describes the localization approach for the Offline Games app, including how to add new locales, naming conventions, testing strategies, and accessibility considerations.

---

## Table of Contents

1. [Overview](#overview)
2. [String Catalog Approach](#string-catalog-approach)
3. [How to Add a New Locale](#how-to-add-a-new-locale)
4. [Naming Conventions for Localization Keys](#naming-conventions-for-localization-keys)
5. [String Interpolation and Plurals](#string-interpolation-and-plurals)
6. [Testing Localization](#testing-localization)
7. [RTL Language Considerations](#rtl-language-considerations)
8. [Accessibility and VoiceOver Strings](#accessibility-and-voiceover-strings)
9. [Localization Checklist](#localization-checklist)

---

## Overview

The project uses Apple's **String Catalog** (`.xcstrings`) format, introduced in Xcode 15 and fully supported in Xcode 26. String Catalogs provide:

- A single file per target that contains all translations for all locales.
- Automatic extraction of `String(localized:)` and `Text()` strings from Swift code.
- Built-in support for pluralization rules, string interpolation, and device variations.
- A visual editor in Xcode for translators.

The app's base development language is **English (en)**.

---

## String Catalog Approach

### File Location

Each package that contains user-facing strings has its own string catalog:

```
Packages/GameUI/Sources/GameUI/Resources/Localizable.xcstrings        # Shared UI strings
Packages/BlockPuzzle/Sources/BlockPuzzle/Resources/Localizable.xcstrings
Packages/SnakeGame/Sources/SnakeGame/Resources/Localizable.xcstrings
Packages/BreakoutGame/Sources/BreakoutGame/Resources/Localizable.xcstrings
Packages/MinesweeperGame/Sources/MinesweeperGame/Resources/Localizable.xcstrings
Packages/MemoryMatch/Sources/MemoryMatch/Resources/Localizable.xcstrings
Packages/ReactionTap/Sources/ReactionTap/Resources/Localizable.xcstrings
App/Resources/Localizable.xcstrings                                     # App-level strings
```

### Using Localized Strings in Swift

SwiftUI `Text` views automatically look up string keys:

```swift
// Automatically localized via the string catalog
Text("game.score.label")

// With interpolation
Text("game.score.value \(score)")

// Using String(localized:) for non-Text contexts
let title = String(localized: "game.pause.title")
```

### String Catalog File Format

The `.xcstrings` file is JSON. Xcode provides a visual editor, but the underlying format looks like:

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

1. Open the Xcode project.
2. Select the project in the navigator (not a target).
3. Under **Info > Localizations**, click the `+` button.
4. Select the language (e.g., French, Japanese, Simplified Chinese).
5. Xcode will add the language to all `.xcstrings` files.

### Step 2: Translate strings

1. Open any `.xcstrings` file in Xcode.
2. Select the new language in the sidebar.
3. For each string key, enter the translated value.
4. Mark each string as "Translated" (green checkmark) when complete.
5. Strings marked "New" (blue) or "Needs Review" (yellow) will fall back to the base language.

### Step 3: Handle plurals (if needed)

Some strings need plural variations. Xcode handles this automatically when it detects interpolated integer values:

```swift
Text("game.lines.cleared \(linesCleared)")
```

In the string catalog, expand this key to provide plural forms:

| Plural Category | English | Japanese |
|---|---|---|
| zero | "No lines cleared" | "ラインクリアなし" |
| one | "1 line cleared" | "1ラインクリア" |
| other | "%lld lines cleared" | "%lldラインクリア" |

### Step 4: Test the new locale

See [Testing Localization](#testing-localization) below.

### Currently Supported Locales

| Code | Language | Status |
|---|---|---|
| `en` | English | Base language |
| `ja` | Japanese | Planned |
| `zh-Hans` | Simplified Chinese | Planned |
| `es` | Spanish | Planned |
| `de` | German | Planned |
| `fr` | French | Planned |
| `ar` | Arabic (RTL) | Planned |

---

## Naming Conventions for Localization Keys

### Key Format

Use a dot-separated hierarchy: `<module>.<screen>.<element>`.

```
game.score.label              # "Score"
game.score.value              # "%lld" (interpolated)
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

1. **Always use camelCase** for the final segment: `game.over.playAgain`, not `game.over.play_again`.
2. **Prefix with module name** for game-specific strings: `blockPuzzle.name`, `snake.description`.
3. **Use generic prefixes** for shared strings: `game.`, `catalog.`, `settings.`.
4. **Never use the English text as the key**. Use semantic keys like `game.over.title` instead of `"Game Over"`. This allows the English text to change without breaking translations.
5. **Keep keys short but descriptive**. Aim for 3-4 segments maximum.
6. **Document context in the string catalog comment field** when the meaning is ambiguous.

---

## String Interpolation and Plurals

### Simple Interpolation

```swift
// Swift code
Text("game.score.value \(score)")

// String catalog entry for "en":
// "Score: %lld"

// String catalog entry for "ja":
// "スコア: %lld"
```

### Multiple Interpolations

```swift
Text("game.stats.summary \(level) \(score)")

// "en": "Level %lld - Score %lld"
// Translators can reorder: "ja": "スコア %2$lld - レベル %1$lld"
```

### Plural Variations

For strings that include counts, Xcode automatically offers plural categories based on the target language's CLDR plural rules:

- **English**: one, other
- **Japanese**: other (Japanese has no grammatical plural)
- **Arabic**: zero, one, two, few, many, other
- **French**: one, many, other

### Device Variations

String catalogs support device-specific variants (iPhone vs. iPad). Use this sparingly:

```
"game.controls.hint" (iPhone): "Tap to play"
"game.controls.hint" (iPad):   "Tap or use keyboard to play"
```

---

## Testing Localization

### Method 1: Xcode Scheme Override

1. Edit Scheme > Run > Options.
2. Set **App Language** to the target locale.
3. Set **App Region** to the matching region.
4. Run the app. All strings will use the selected locale.

### Method 2: Double-Length Pseudolanguage

Test for layout issues with long translations:

1. Edit Scheme > Run > Options.
2. Set **App Language** to "Double Length Pseudolanguage".
3. All strings are doubled (e.g., "Score" becomes "Score Score").
4. Check that all UI elements still fit.

### Method 3: Accented Pseudolanguage

Test for hardcoded strings (strings that bypass localization):

1. Edit Scheme > Run > Options.
2. Set **App Language** to "Accented Pseudolanguage".
3. Localized strings appear with accents: "[Score]" becomes "[Scoooree]".
4. Any text that appears *without* accents is hardcoded and needs localization.

### Method 4: Right-to-Left Pseudolanguage

Test RTL layout without needing an actual RTL translation:

1. Edit Scheme > Run > Options.
2. Set **App Language** to "Right-to-Left Pseudolanguage".
3. The entire UI flips to RTL.

### Method 5: Preview in Xcode

Use SwiftUI previews with explicit locale:

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

When supporting RTL languages (Arabic, Hebrew), ensure the following:

### Layout Flipping

SwiftUI automatically flips layout for RTL languages when using standard layout containers:

```swift
// Automatically flips in RTL
HStack {
    Image(systemName: "star.fill")
    Text("game.score.label")
    Spacer()
    Text("\(score)")
}
// In LTR: [star] Score         100
// In RTL: 100         نتيجة [star]
```

### Leading/Trailing vs. Left/Right

Always use `.leading` and `.trailing` instead of `.left` and `.right`:

```swift
// Good: adapts to RTL
.padding(.leading, 16)
.frame(alignment: .trailing)

// Bad: does not adapt to RTL
.padding(.left, 16)
.frame(alignment: .right)
```

### Game Board Direction

Game boards (grids) generally should NOT flip in RTL, because the game logic depends on absolute coordinates. Only UI chrome (buttons, labels, navigation) should flip:

```swift
// Prevent the game board from flipping
GameBoardView()
    .environment(\.layoutDirection, .leftToRight)  // Pin to LTR

// Let the HUD flip naturally
HUDOverlayView()
    // Inherits system layout direction
```

### Number Formatting

Use `formatted()` for numbers to respect locale:

```swift
Text(score.formatted())  // "1,234" in English, "1.234" in German, "١٬٢٣٤" in Arabic
```

### Text Alignment

Use `.multilineTextAlignment(.leading)` instead of `.left`:

```swift
Text(longDescription)
    .multilineTextAlignment(.leading)  // Adapts to RTL
```

---

## Accessibility and VoiceOver Strings

### Separate Accessibility Labels

VoiceOver labels should describe what the element *is* or *does*, not just repeat the visual text:

```swift
GlassButton("game.pause.resume") {
    // ...
}
.accessibilityLabel(Text("accessibility.pause.resume"))
// Visual: "Resume"
// VoiceOver: "Resume game"
```

### Localization Keys for Accessibility

Use an `accessibility.` prefix for VoiceOver-specific strings:

```
accessibility.game.board          # "Game board, 12 columns by 24 rows"
accessibility.game.score          # "Current score: %lld"
accessibility.game.piece.current  # "Current piece: L-shape at column %lld"
accessibility.catalog.game        # "%@ game. %@"  (name, description)
accessibility.button.play         # "Start game"
accessibility.button.pause        # "Pause game"
```

### Accessibility Hints

Hints describe what *will happen* when the user activates the element:

```swift
GlassButton("game.over.playAgain") { ... }
    .accessibilityLabel(Text("accessibility.button.playAgain.label"))
    .accessibilityHint(Text("accessibility.button.playAgain.hint"))
// Label: "Play Again"
// Hint: "Starts a new game"
```

### Dynamic Type

All text should support Dynamic Type. Using `AppTheme` fonts (which are based on system text styles) ensures this:

```swift
Text("game.score.label")
    .font(AppTheme.bodyFont)  // Scales with Dynamic Type
```

Avoid fixed font sizes unless absolutely necessary for game rendering.

### VoiceOver for Game State Changes

Post accessibility notifications when important state changes occur:

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

For each new locale:

- [ ] Language added in Xcode project settings
- [ ] All string catalog keys translated
- [ ] Plural rules configured for the language
- [ ] All accessibility strings translated
- [ ] UI tested with the locale -- no truncation or overflow
- [ ] Double-length pseudolanguage tested for layout
- [ ] RTL layout tested (if applicable)
- [ ] Number and date formatting verified
- [ ] App Store metadata translated (name, description, keywords)
- [ ] Screenshots generated in the locale

For each new user-facing string:

- [ ] Uses a semantic key (not the English text)
- [ ] Key follows the naming convention (`module.screen.element`)
- [ ] Added to the appropriate `.xcstrings` file
- [ ] Accessibility label provided if different from visual text
- [ ] Tested with VoiceOver
- [ ] Tested with Double-Length Pseudolanguage for layout
