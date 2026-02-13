# App Store Submission Checklist

A comprehensive checklist for submitting the Offline Games app to the Apple App Store. Covers metadata, assets, compliance, testing, and common rejection reasons.

---

## Table of Contents

1. [App Metadata](#app-metadata)
2. [Screenshots and Preview Video](#screenshots-and-preview-video)
3. [Privacy Policy](#privacy-policy)
4. [Age Rating](#age-rating)
5. [App Review Guidelines for Games](#app-review-guidelines-for-games)
6. [Accessibility Compliance](#accessibility-compliance)
7. [Required Device Capabilities](#required-device-capabilities)
8. [Launch Screen Configuration](#launch-screen-configuration)
9. [TestFlight Beta Testing](#testflight-beta-testing)
10. [Common Rejection Reasons and How to Avoid Them](#common-rejection-reasons-and-how-to-avoid-them)
11. [Pre-Submission Checklist](#pre-submission-checklist)

---

## App Metadata

### App Name

- **Name**: "Offline Games"
- **Subtitle**: "Classic & Original Mini-Games" (30 character limit)
- Maximum 30 characters for the name.
- Do not include trademarked game names (no "Tetris," "Arkanoid," etc.).
- See [IP Considerations](IPConsiderations.md) for naming guidelines.

### Description

The description should be clear, informative, and keyword-rich without being spammy.

**Template:**

```
Offline Games is a collection of six classic and original mini-games,
designed to be played anywhere -- no internet required.

GAMES INCLUDED:
- Block Puzzle: Arrange falling pieces to clear lines
- Snake: Guide the snake to eat and grow
- Breakout: Smash bricks with a bouncing ball
- Minesweeper: Uncover the grid without hitting mines
- Memory Match: Find matching pairs of cards
- Reaction Tap: Test your reflexes with speed challenges

FEATURES:
- 100% offline -- play anywhere, anytime
- No ads, no in-app purchases, no tracking
- Beautiful iOS 26 design with Liquid Glass interface
- High score tracking for every game
- Haptic feedback and sound effects
- Supports Dynamic Type and VoiceOver
- Smooth Metal-powered graphics

Privacy first: This app collects absolutely no data.
Your scores stay on your device.
```

### Keywords

100 character limit, comma-separated. Focus on discoverability:

```
offline games,puzzle,snake,block puzzle,minesweeper,breakout,memory,reaction,no ads,no wifi,classic
```

Tips:
- Do not repeat words already in the app name or subtitle.
- Do not use trademarked terms.
- Do not use competitor app names.
- Use singular forms (Apple searches both "game" and "games" from "game").

### Category

- **Primary**: Games
- **Secondary**: Puzzle (or Entertainment)

### Content Rights

- Confirm that the app does not contain, show, or access third-party content.
- All content is original or system-provided (SF Symbols).

---

## Screenshots and Preview Video

### Screenshot Requirements

| Device | Size (pixels) | Required |
|---|---|---|
| iPhone 6.9" (iPhone 16 Pro Max) | 1320 x 2868 | Yes (required for newest device) |
| iPhone 6.7" (iPhone 15 Pro Max) | 1290 x 2796 | Yes |
| iPhone 6.5" (iPhone 15 Plus) | 1284 x 2778 | Optional (can reuse 6.7") |
| iPhone 5.5" (iPhone 8 Plus) | 1242 x 2208 | Only if supporting older devices |
| iPad Pro 12.9" (6th gen) | 2048 x 2732 | If iPad support is added |

### Screenshot Content Plan

Provide 6-10 screenshots per device size. Recommended sequence:

1. **Game catalog view** -- shows all 6 games in the Liquid Glass UI
2. **Block Puzzle** gameplay in action
3. **Snake** gameplay showing the snake and food
4. **Breakout** gameplay with bricks and ball
5. **Minesweeper** mid-game board
6. **Memory Match** with some cards flipped
7. **Reaction Tap** gameplay
8. **Game Over screen** showing high score
9. **Settings/theme** view (if applicable)

### Screenshot Guidelines

- Use actual in-app content (no Photoshop mockups of fake UI).
- Do not include device bezels in the screenshot file -- App Store Connect adds them.
- Ensure the status bar shows a clean state (full battery, full signal, reasonable time).
- Text in screenshots must be legible.
- If adding overlay text (marketing messages), keep it concise.

### App Preview Video

- Up to 30 seconds.
- Show actual gameplay from multiple games.
- No spoken narration required (most users watch without sound).
- Suggested flow: catalog view (2s) -> Block Puzzle (5s) -> Snake (5s) -> Breakout (5s) -> Minesweeper (3s) -> Memory Match (3s) -> Reaction Tap (3s) -> end card (4s).
- Capture with Xcode's screen recording or QuickTime.

---

## Privacy Policy

### No Data Collection

This app collects absolutely no user data. However, Apple still requires a privacy policy URL for all apps.

### Privacy Nutrition Label (App Privacy)

In App Store Connect, under App Privacy:

- **Data Collection**: Select "No, we do not collect data from this app."
- This results in the "No Data Collected" privacy label.

### Privacy Policy URL

Host a simple privacy policy page at a stable URL. Content:

```
Privacy Policy for Offline Games

Last updated: [Date]

Offline Games does not collect, store, or transmit any personal data.
The app operates entirely offline and does not connect to any servers.

- No personal information is collected
- No usage analytics are gathered
- No advertising identifiers are used
- No data is shared with third parties
- High scores and settings are stored locally on your device only

Contact: [your email]
```

### App Tracking Transparency

Since the app does not track users, the ATT framework is not required. Do not include the `NSUserTrackingUsageDescription` key.

---

## Age Rating

### Rating: 4+

The app qualifies for a **4+ (Everyone)** age rating based on these criteria:

| Category | Answer | Notes |
|---|---|---|
| Cartoon or Fantasy Violence | None | No violence of any kind |
| Realistic Violence | None | No realistic violence |
| Prolonged Graphic or Sadistic Violence | None | N/A |
| Profanity or Crude Humor | None | No text beyond game UI |
| Mature/Suggestive Themes | None | N/A |
| Horror/Fear Themes | None | N/A |
| Medical/Treatment Information | None | N/A |
| Alcohol, Tobacco, or Drug Use | None | N/A |
| Simulated Gambling | None | No gambling mechanics |
| Sexual Content or Nudity | None | N/A |
| Unrestricted Web Access | None | App is 100% offline |

### COPPA Compliance

Since the app is rated 4+ and may be used by children under 13:
- No data collection (COPPA-compliant by default).
- No third-party SDKs that might collect data.
- No advertising.
- No social features, chat, or user-generated content.

---

## App Review Guidelines for Games

### Guideline 4.0 - Design (Minimum Functionality)

Apps must provide sufficient value. Our app includes 6 fully playable games, which exceeds the minimum functionality threshold.

### Guideline 4.2 - Minimum Functionality

- Each game must be fully functional and playable.
- No "coming soon" placeholder games.
- The app must not crash on any supported device.

### Guideline 4.3 - Spam

The app must not be a trivial clone with no unique value. Our differentiation:
- Six games in one app (not 6 separate apps).
- Original visual design (iOS 26 Liquid Glass).
- Original game variations (pentomino pieces in Block Puzzle, etc.).

### Guideline 2.3 - Accurate Metadata

- Screenshots must show actual app UI.
- Description must accurately reflect app content.
- Do not claim features that do not exist.

### Guideline 5.1 - Privacy

- Privacy policy must be provided.
- Privacy nutrition label must be accurate.
- No data collection means no privacy concerns.

### Guideline 3.1 - Payments

- If the app is free with no IAP, no concerns.
- If the app is paid, the price must reflect the content provided.
- No hidden paywalls or misleading "free" claims.

---

## Accessibility Compliance

Apple values accessibility and may reject apps that are unusable with assistive technologies.

### Required

- [ ] All interactive elements have accessibility labels.
- [ ] VoiceOver can navigate the entire app (catalog, each game, settings).
- [ ] Dynamic Type is supported -- text scales with the system font size setting.
- [ ] Sufficient color contrast (4.5:1 for text, 3:1 for large text/graphics).
- [ ] Touch targets are at least 44x44 points.

### Recommended

- [ ] VoiceOver announces game state changes (score updates, game over).
- [ ] Reduce Motion is respected (minimize animations when enabled).
- [ ] Bold Text preference is respected.
- [ ] Switch Control can navigate the app.
- [ ] All game UI elements are reachable via VoiceOver.

### Testing

1. Enable VoiceOver (Settings > Accessibility > VoiceOver) and navigate the entire app.
2. Enable Dynamic Type at the largest setting and verify no text is truncated.
3. Run the Accessibility Inspector (Xcode > Open Developer Tool > Accessibility Inspector) on every screen.
4. Test with Increase Contrast enabled.

---

## Required Device Capabilities

### Metal

The app requires Metal for GPU rendering. Add to `Info.plist`:

```xml
<key>UIRequiredDeviceCapabilities</key>
<array>
    <string>metal</string>
</array>
```

This prevents the app from being downloaded on devices without Metal support (pre-A7 devices, which cannot run iOS 26 anyway).

### ARM64

All iOS 26 devices are ARM64. No additional capability key is needed since the app targets iOS 26+.

### No Other Requirements

The app does not require:
- Camera (`still-camera`)
- GPS (`location-services`, `gps`)
- Cellular data (`telephony`)
- Bluetooth (`bluetooth-le`)
- ARKit (`arkit`)

Do NOT list capabilities the app does not actually require -- this unnecessarily limits the audience.

---

## Launch Screen Configuration

### Storyboard-Based Launch Screen

Use a launch screen storyboard (or `Info.plist` configuration) for the initial loading screen.

In `Info.plist`:

```xml
<key>UILaunchScreen</key>
<dict>
    <key>UIColorName</key>
    <string>LaunchScreenBackground</string>
    <key>UIImageName</key>
    <string>LaunchLogo</string>
    <key>UIImageRespectsSafeAreaInsets</key>
    <true/>
</dict>
```

### Guidelines

- Keep the launch screen minimal (solid color + app logo).
- The launch screen should match the first screen the user sees (avoid a jarring transition).
- Do not include text that would need localization (Apple recommends avoiding text on launch screens).
- Do not show a loading indicator -- the launch screen should feel like the app is already loaded.
- Ensure the launch screen works in both portrait and landscape.
- Test on different device sizes to ensure proper scaling.

---

## TestFlight Beta Testing

### Step 1: Archive and Upload

1. In Xcode, select the "Any iOS Device" destination.
2. Product > Archive.
3. In the Organizer, select the archive and click "Distribute App."
4. Choose "TestFlight & App Store" > Upload.
5. Wait for processing (5-30 minutes).

### Step 2: Configure TestFlight in App Store Connect

1. Log in to [App Store Connect](https://appstoreconnect.apple.com).
2. Go to the app > TestFlight tab.
3. Wait for the build to appear and complete processing.
4. Fill in the "What to Test" description for beta testers.
5. Set up any test groups.

### Step 3: Internal Testing

Internal testers (up to 100, must be App Store Connect users):
- Add testers under TestFlight > Internal Testing.
- Builds are available immediately after processing (no Beta App Review needed).
- Test on multiple device sizes and iOS versions.

### Step 4: External Testing

External testers (up to 10,000):
- Create a public or invite-only group under TestFlight > External Testing.
- First build requires Beta App Review (1-2 days).
- Subsequent builds usually auto-approve if changes are minor.

### Step 5: Beta Testing Checklist

- [ ] All 6 games launch and are playable
- [ ] No crashes on any supported device
- [ ] Game state is preserved when backgrounding and returning
- [ ] High scores persist between sessions
- [ ] Sound effects and haptics work correctly
- [ ] VoiceOver navigation works for all screens
- [ ] Dynamic Type renders correctly at all sizes
- [ ] Performance is smooth (consistent 60fps for action games)
- [ ] Memory usage is reasonable (no leaks)
- [ ] App size is acceptable (aim for under 50MB)

---

## Common Rejection Reasons and How to Avoid Them

### 1. Crashes and Bugs

**Rejection reason**: "Your app crashed during our review."

**Prevention**:
- Test on physical devices, not just the simulator.
- Test on the oldest supported device (iPhone SE 3rd gen for iOS 26).
- Test with Low Power Mode enabled.
- Test with limited storage (nearly full device).
- Run Instruments > Leaks to check for memory leaks.
- Run Thread Sanitizer to catch concurrency bugs.

### 2. Broken Links or Missing Content

**Rejection reason**: "The privacy policy URL did not load."

**Prevention**:
- Verify the privacy policy URL is accessible from a clean browser session.
- Ensure all placeholder content is replaced with real content.
- No "lorem ipsum" or "TODO" text anywhere in the app.

### 3. Insufficient Metadata

**Rejection reason**: "Your screenshots do not reflect the app experience."

**Prevention**:
- Use actual in-app screenshots, not mockups.
- Update screenshots whenever the UI changes significantly.
- Ensure the description accurately describes what the app does.

### 4. Intellectual Property Violation

**Rejection reason**: "Your app uses trademarked content."

**Prevention**:
- Follow the guidelines in [IP Considerations](IPConsiderations.md).
- Do not use "Tetris," "Tetrimino," "Arkanoid," or "Nokia" anywhere.
- Ensure all assets are original.
- Do not reference trademarked games in metadata.

### 5. Minimum Functionality

**Rejection reason**: "Your app does not provide enough features."

**Prevention**:
- All 6 games must be fully playable (no placeholder "coming soon" games).
- The app provides clear value beyond what a website could offer.
- Each game should have reasonable depth (scoring, progression, etc.).

### 6. Guideline 4.3 - Spam / Copycat

**Rejection reason**: "Your app is a clone of [existing game]."

**Prevention**:
- The app bundles 6 games (not a single-game clone).
- Visual design is clearly original (iOS 26 Liquid Glass, not retro pixel art).
- Block Puzzle uses custom pentomino pieces and non-standard grid.
- Include original games (Memory Match, Reaction Tap) that are not clones.

### 7. Privacy Issues

**Rejection reason**: "Your app accesses [data type] without proper disclosure."

**Prevention**:
- The app accesses NO user data, camera, location, contacts, or network.
- Confirm the privacy nutrition label says "No Data Collected."
- Do not include any third-party SDKs (analytics, ads, crash reporting) that might collect data.

### 8. Performance Issues

**Rejection reason**: "Your app does not perform as expected."

**Prevention**:
- Profile with Instruments to ensure 60fps gameplay.
- Test on the oldest supported device.
- Ensure Metal shaders compile and run correctly on all GPU architectures.
- Test game loop timing on different devices (avoid frame rate assumptions).

### 9. UI Design Issues

**Rejection reason**: "Your app does not follow the Human Interface Guidelines."

**Prevention**:
- Use standard navigation patterns.
- Support both portrait and landscape if applicable.
- Use safe area insets to avoid content being hidden by the Dynamic Island or home indicator.
- Support all iPhone screen sizes.

### 10. Missing Required Device Capabilities

**Rejection reason**: "Your app crashes on devices that meet the listed requirements."

**Prevention**:
- Only list device capabilities the app truly requires (Metal).
- Test on the lowest-spec device that meets the requirements.
- Handle Metal device creation failure gracefully (show an error, do not crash).

---

## Pre-Submission Checklist

### App Store Connect

- [ ] App name, subtitle, and description are finalized
- [ ] Keywords are set (100 character max)
- [ ] Category is set to Games
- [ ] Privacy policy URL is live and accessible
- [ ] Privacy nutrition label is configured ("No Data Collected")
- [ ] Age rating questionnaire is completed (4+)
- [ ] App icon (1024x1024) is uploaded
- [ ] Screenshots are uploaded for all required device sizes
- [ ] App preview video is uploaded (optional but recommended)
- [ ] Price and availability are configured
- [ ] Content rights are confirmed

### Build Quality

- [ ] All 6 games launch, play, and end correctly
- [ ] No crashes on any supported device
- [ ] No memory leaks (verified with Instruments)
- [ ] 60fps performance on oldest supported device
- [ ] App size is reasonable (< 50MB)
- [ ] No compiler warnings
- [ ] All tests pass

### Compliance

- [ ] No trademarked names in any user-facing text or metadata
- [ ] All art, sound, and music assets are original or licensed
- [ ] App icon is original
- [ ] Accessibility audit completed (VoiceOver, Dynamic Type, contrast)
- [ ] No data collection or third-party SDKs

### Device Testing

- [ ] iPhone SE (3rd gen) -- smallest screen
- [ ] iPhone 16 -- standard size
- [ ] iPhone 16 Pro Max -- largest screen
- [ ] iPad (if supported)
- [ ] Tested in portrait and landscape
- [ ] Tested with Low Power Mode
- [ ] Tested with Airplane Mode (app should work identically)
