[English](AppStoreChecklist.md) | [简体中文](AppStoreChecklist.zh-Hans.md)

# App Store Submission Checklist

提交 Offline Games 应用到 Apple App Store 的全面检查清单。涵盖元数据、资产、合规性、测试以及常见的拒绝原因。

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

- **名称**: "Offline Games"
- **副标题**: "Classic & Original Mini-Games" (限 30 个字符)
- 名称最大限制为 30 个字符。
- 请勿包含受商标保护的游戏名称（不要出现 "Tetris"、"Arkanoid" 等）。
- 参见 [IP Considerations](IPConsiderations.zh-Hans.md) 了解命名指南。

### Description

描述应清晰、信息丰富且富含关键词，同时避免垃圾内容。

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

限 100 个字符，用逗号分隔。专注于可发现性：

```
offline games,puzzle,snake,block puzzle,minesweeper,breakout,memory,reaction,no ads,no wifi,classic
```

提示：
- 不要重复应用名称或副标题中已有的词汇。
- 不要使用受商标保护的术语。
- 不要使用竞争对手的应用名称。
- 使用单数形式（Apple 会通过 "game" 同时搜索 "game" 和 "games"）。

### Category

- **主分类**: 游戏 (Games)
- **次分类**: 解谜 (Puzzle) 或 娱乐 (Entertainment)

### Content Rights

- 确认应用不包含、不展示也不访问第三方内容。
- 所有内容均为原创或系统提供 (SF Symbols)。

---

## Screenshots and Preview Video

### Screenshot Requirements

| 设备 | 尺寸 (像素) | 是否必需 |
|---|---|---|
| iPhone 6.9" (iPhone 16 Pro Max) | 1320 x 2868 | 是 (最新设备必需) |
| iPhone 6.7" (iPhone 15 Pro Max) | 1290 x 2796 | 是 |
| iPhone 6.5" (iPhone 15 Plus) | 1284 x 2778 | 可选 (可复用 6.7" 尺寸) |
| iPhone 5.5" (iPhone 8 Plus) | 1242 x 2208 | 仅在支持旧款设备时需要 |
| iPad Pro 12.9" (第 6 代) | 2048 x 2732 | 如果添加了 iPad 支持 |

### Screenshot Content Plan

每个设备尺寸提供 6-10 张截图。建议顺序如下：

1. **游戏目录视图** —— 展示 Liquid Glass UI 中的全部 6 款游戏
2. **方块拼图 (Block Puzzle)** 游戏进行中的画面
3. **贪吃蛇 (Snake)** 展示蛇和食物的画面
4. **打砖块 (Breakout)** 带有砖块和球的画面
5. **扫雷 (Minesweeper)** 游戏中的棋盘
6. **记忆配对 (Memory Match)** 翻开部分卡片的画面
7. **反应点击 (Reaction Tap)** 游戏画面
8. **游戏结束界面** 展示高分
9. **设置/主题** 视图（如果适用）

### Screenshot Guidelines

- 使用真实的应用内内容（不要使用虚假 UI 的 Photoshop 样机）。
- 截图文件中不要包含设备外壳边缘 —— App Store Connect 会自动添加。
- 确保状态栏显示干净的状态（电量满格、信号满格、合理的时间）。
- 截图中的文字必须清晰易读。
- 如果添加叠加文本（营销信息），请保持简洁。

### App Preview Video

- 最长 30 秒。
- 展示多款游戏的真实玩法。
- 不需要旁白解说（大多数用户在静音状态下观看）。
- 建议流程：目录视图 (2s) -> 方块拼图 (5s) -> 贪吃蛇 (5s) -> 打砖块 (5s) -> 扫雷 (3s) -> 记忆配对 (3s) -> 反应点击 (3s) -> 结束卡片 (4s)。
- 使用 Xcode 的屏幕录制功能或 QuickTime 进行录制。

---

## Privacy Policy

### No Data Collection

此应用绝对不收集任何用户数据。然而，Apple 仍要求所有应用提供隐私政策 URL。

### Privacy Nutrition Label (App Privacy)

在 App Store Connect 的“应用隐私”下：

- **数据收集**: 选择“否，我们不从此应用中收集数据”。
- 这将生成“未收集数据”的隐私标签。

### Privacy Policy URL

在一个稳定的 URL 上托管一个简单的隐私政策页面。内容如下：

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

由于应用不跟踪用户，因此不需要 ATT 框架。请勿包含 `NSUserTrackingUsageDescription` 键。

---

## Age Rating

### Rating: 4+

根据以下标准，该应用符合 **4+ (全年龄)** 分级：

| 分类 | 回答 | 备注 |
|---|---|---|
| 卡通或幻想暴力 | 无 | 没有任何形式的暴力 |
| 写实暴力 | 无 | 无写实暴力 |
| 连贯的图形或施虐暴力 | 无 | 不适用 |
| 粗俗语言或低俗幽默 | 无 | 除游戏 UI 外无文本 |
| 成人/暗示性主题 | 无 | 不适用 |
| 恐怖/惊悚主题 | 无 | 不适用 |
| 医疗/治疗信息 | 无 | 不适用 |
| 酒精、烟草或药物使用 | 无 | 不适用 |
| 模拟赌博 | 无 | 无赌博机制 |
| 性相关内容或裸体 | 无 | 不适用 |
| 无限制的网络访问 | 无 | 应用 100% 离线 |

### COPPA Compliance

由于应用评级为 4+ 且可能被 13 岁以下儿童使用：
- 无数据收集（默认符合 COPPA）。
- 无可能收集数据的第三方 SDK。
- 无广告。
- 无社交功能、聊天或用户生成内容。

---

## App Review Guidelines for Games

### Guideline 4.0 - Design (Minimum Functionality)

应用必须提供足够的价值。我们的应用包含 6 款完全可玩的应用，超出了最低功能阈值。

### Guideline 4.2 - Minimum Functionality

- 每款游戏必须功能完整且可玩。
- 不得有“即将推出”的占位游戏。
- 应用不得在任何支持的设备上崩溃。

### Guideline 4.3 - Spam

应用不得是没有任何独特价值的平庸克隆版。我们的差异化在于：
- 一个应用内包含六款游戏（而不是 6 个独立应用）。
- 原创视觉设计 (iOS 26 Liquid Glass)。
- 原创游戏变体（方块拼图中的五格骨牌等）。

### Guideline 2.3 - Accurate Metadata

- 截图必须展示真实的应用 UI。
- 描述必须准确反映应用内容。
- 不要宣称不存在的功能。

### Guideline 5.1 - Privacy

- 必须提供隐私政策。
- 隐私营养标签必须准确。
- 无数据收集意味着没有隐私顾虑。

### Guideline 3.1 - Payments

- 如果应用免费且无 App 内购买 (IAP)，则无此类顾虑。
- 如果应用收费，价格必须反映所提供的内容。
- 不得有隐藏的付费墙或误导性的“免费”声明。

---

## Accessibility Compliance

Apple 非常重视辅助功能，可能会拒绝那些无法使用辅助技术的应用。

### Required

- [ ] 所有交互元素都有辅助功能标签 (Accessibility Labels)。
- [ ] VoiceOver 可以导航整个应用（目录、每款游戏、设置）。
- [ ] 支持动态字体 (Dynamic Type) —— 文本随系统字体大小设置缩放。
- [ ] 足够的色彩对比度（文本 4.5:1，大文本/图形 3:1）。
- [ ] 触摸目标至少为 44x44 点。

### Recommended

- [ ] VoiceOver 播报游戏状态变化（分数更新、游戏结束）。
- [ ] 遵循“减弱动态效果”设置（启用时减少动画）。
- [ ] 遵循“粗体文本”偏好设置。
- [ ] 切换控制 (Switch Control) 可以导航应用。
- [ ] 所有游戏 UI 元素均可通过 VoiceOver 触达。

### Testing

1. 启用 VoiceOver（设置 > 辅助功能 > VoiceOver）并导航整个应用。
2. 将动态字体设置为最大，验证文本是否被截断。
3. 在每个屏幕上运行辅助功能检查器 (Xcode > Open Developer Tool > Accessibility Inspector)。
4. 在启用“增强对比度”的情况下进行测试。

---

## Required Device Capabilities

### Metal

应用需要 Metal 进行 GPU 渲染。在 `Info.plist` 中添加：

```xml
<key>UIRequiredDeviceCapabilities</key>
<array>
    <string>metal</string>
</array>
```

这可以防止应用在不支持 Metal 的设备上被下载（A7 之前的设备，这些设备本身也无法运行 iOS 26）。

### ARM64

所有 iOS 26 设备均为 ARM64。由于应用目标版本为 iOS 26+，因此不需要额外的能力键。

### No Other Requirements

应用不需要：
- 摄像头 (`still-camera`)
- GPS (`location-services`, `gps`)
- 蜂窝数据 (`telephony`)
- 蓝牙 (`bluetooth-le`)
- ARKit (`arkit`)

请勿列出应用实际不需要的功能 —— 这会不必要地限制受众群体。

---

## Launch Screen Configuration

### Storyboard-Based Launch Screen

使用启动屏幕故事板（或 `Info.plist` 配置）作为初始加载屏幕。

在 `Info.plist` 中：

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

- 保持启动屏幕极简（纯色 + 应用图标）。
- 启动屏幕应与用户看到的第一个屏幕匹配（避免突兀的过渡）。
- 不要包含需要本地化的文本（Apple 建议避免在启动屏幕上使用文本）。
- 不要显示加载指示器 —— 启动屏幕应该让用户感觉应用已经加载完成。
- 确保启动屏幕在竖屏和横屏下均正常显示。
- 在不同尺寸的设备上测试以确保缩放正确。

---

## TestFlight Beta Testing

### Step 1: Archive and Upload

1. 在 Xcode 中，选择 "Any iOS Device" 目标。
2. Product > Archive。
3. 在 Organizer 中，选择存档并点击 "Distribute App"。
4. 选择 "TestFlight & App Store" > Upload。
5. 等待处理（5-30 分钟）。

### Step 2: Configure TestFlight in App Store Connect

1. 登录 [App Store Connect](https://appstoreconnect.apple.com)。
2. 进入应用 > TestFlight 选项卡。
3. 等待构建版本出现并完成处理。
4. 为 Beta 测试人员填写“测试内容”说明。
5. 设置测试小组。

### Step 3: Internal Testing

内部测试人员（最多 100 人，必须是 App Store Connect 用户）：
- 在 TestFlight > 内部测试下添加测试人员。
- 构建版本在处理完成后立即生效（无需 Beta 版应用审核）。
- 在多种设备尺寸和 iOS 版本上测试。

### Step 4: External Testing

外部测试人员（最多 10,000 人）：
- 在 TestFlight > 外部测试下创建公开或仅限邀请的小组。
- 第一个构建版本需要 Beta 版应用审核（1-2 天）。
- 如果更改较小，后续构建版本通常会自动批准。

### Step 5: Beta Testing Checklist

- [ ] 所有 6 款游戏均能启动且可玩
- [ ] 在任何支持的设备上都没有崩溃
- [ ] 退到后台并返回时游戏状态得以保留
- [ ] 高分在不同会话之间持久保存
- [ ] 音效和触感反馈正常工作
- [ ] VoiceOver 导航在所有屏幕上均正常工作
- [ ] 动态字体在所有尺寸下渲染正确
- [ ] 性能流畅（动作类游戏稳定在 60fps）
- [ ] 内存使用合理（无泄漏）
- [ ] 应用体积可接受（目标在 50MB 以下）

---

## Common Rejection Reasons and How to Avoid Them

### 1. Crashes and Bugs

**拒绝原因**: "您的应用在我们的审核过程中崩溃了。"

**预防措施**:
- 在实体设备上测试，而不仅仅是模拟器。
- 在支持的最旧设备上测试（针对 iOS 26 的 iPhone SE 第 3 代）。
- 在开启低电量模式的情况下测试。
- 在存储空间受限（设备几乎已满）的情况下测试。
- 运行 Instruments > Leaks 检查内存泄漏。
- 运行 Thread Sanitizer 以捕捉并发错误。

### 2. Broken Links or Missing Content

**拒绝原因**: "隐私政策 URL 无法加载。"

**预防措施**:
- 验证隐私政策 URL 在干净的浏览器会话中可以访问。
- 确保所有占位内容都已替换为真实内容。
- 应用中任何地方都不要出现 "lorem ipsum" 或 "TODO" 文本。

### 3. Insufficient Metadata

**拒绝原因**: "您的截图不能反映应用体验。"

**预防措施**:
- 使用真实的应用内截图，而不是样机。
- 只要 UI 发生重大变化，就更新截图。
- 确保描述准确描述应用的功能。

### 4. Intellectual Property Violation

**拒绝原因**: "您的应用使用了受商标保护的内容。"

**预防措施**:
- 遵循 [IP Considerations](IPConsiderations.zh-Hans.md) 中的指南。
- 不要在任何地方使用 "Tetris"、"Tetrimino"、"Arkanoid" 或 "Nokia"。
- 确保所有资产均为原创。
- 不要在元数据中引用受商标保护的游戏。

### 5. Minimum Functionality

**拒绝原因**: "您的应用没有提供足够的功能。"

**预防措施**:
- 所有 6 款游戏必须完全可玩（没有“即将推出”的占位游戏）。
- 应用提供的价值要明显超过网站所能提供的。
- 每款游戏都应具有合理的深度（计分、进度等）。

### 6. Guideline 4.3 - Spam / Copycat

**拒绝原因**: "您的应用是 [现有游戏] 的克隆版。"

**预防措施**:
- 该应用捆绑了 6 款游戏（不是单款游戏的克隆）。
- 视觉设计明显具有原创性（iOS 26 Liquid Glass，而非复古像素艺术）。
- 方块拼图使用自定义的五格骨牌和非标准网格。
- 包含非克隆类的原创游戏（记忆配对、反应点击）。

### 7. Privacy Issues

**拒绝原因**: "您的应用在未妥善披露的情况下访问了 [数据类型]。"

**预防措施**:
- 应用不访问任何用户数据、摄像头、位置、通讯录或网络。
- 确认隐私营养标签显示为“未收集数据”。
- 不要包含任何可能收集数据的第三方 SDK（分析、广告、崩溃报告）。

### 8. Performance Issues

**拒绝原因**: "您的应用表现不如预期。"

**预防措施**:
- 使用 Instruments 进行分析以确保 60fps 的游戏体验。
- 在支持的最旧设备上测试。
- 确保 Metal 着色器在所有 GPU 架构上都能正确编译和运行。
- 在不同设备上测试游戏循环计时（避免对帧率做假设）。

### 9. UI Design Issues

**拒绝原因**: "您的应用没有遵循人机交互指南 (Human Interface Guidelines)。"

**预防措施**:
- 使用标准的导航模式。
- 如果适用，支持横屏和竖屏。
- 使用安全区域缩进 (Safe Area Insets) 以避免内容被灵动岛或主屏幕指示条遮挡。
- 支持所有 iPhone 屏幕尺寸。

### 10. Missing Required Device Capabilities

**拒绝原因**: "您的应用在符合所列要求的设备上崩溃。"

**预防措施**:
- 仅列出应用真正需要的设备能力 (Metal)。
- 在符合要求的最低配置设备上测试。
- 优雅地处理 Metal 设备创建失败的情况（显示错误，而不是崩溃）。

---

## Pre-Submission Checklist

### App Store Connect

- [ ] 应用名称、副标题和描述已最终定稿
- [ ] 关键字已设置（最多 100 个字符）
- [ ] 分类已设置为“游戏”
- [ ] 隐私政策 URL 已上线并可访问
- [ ] 隐私营养标签已配置（“未收集数据”）
- [ ] 年龄分级问卷已完成 (4+)
- [ ] 应用图标 (1024x1024) 已上传
- [ ] 已为所有要求的设备尺寸上传截图
- [ ] 已上传应用预览视频（可选但建议提供）
- [ ] 价格和可用性已配置
- [ ] 内容权利已确认

### Build Quality

- [ ] 所有 6 款游戏均能正确启动、运行和结束
- [ ] 在任何支持的设备上都没有崩溃
- [ ] 无内存泄漏（已通过 Instruments 验证）
- [ ] 在最旧的支持设备上达到 60fps 性能
- [ ] 应用体积合理 (< 50MB)
- [ ] 无编译器警告
- [ ] 所有测试均通过

### Compliance

- [ ] 任何面向用户的文本或元数据中均无受商标保护的名称
- [ ] 所有美术、声音和音乐资产均为原创或已获得授权
- [ ] 应用图标为原创
- [ ] 辅助功能审计已完成（VoiceOver、动态字体、对比度）
- [ ] 无数据收集或第三方 SDK

### Device Testing

- [ ] iPhone SE (第 3 代) —— 最小屏幕
- [ ] iPhone 16 —— 标准尺寸
- [ ] iPhone 16 Pro Max —— 最大屏幕
- [ ] iPad（如果支持）
- [ ] 已测试竖屏和横屏
- [ ] 已测试低电量模式
- [ ] 已测试飞行模式（应用应能完全正常工作）
