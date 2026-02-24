[English](CppBridging.md) | [简体中文](CppBridging.zh-Hans.md)

# C++ Bridging Guide

本文档介绍了如何通过 Swift 的原生 C++ 互操作性将 C++ 代码集成到项目中，涵盖了 `CppCore` 包的架构以及如何添加新的 C++ 功能。

---

## Table of Contents

1. [Overview](#overview)
2. [Swift-C++ Interop Setup](#swift-c-interop-setup)
3. [CppCore Package Structure](#cppcore-package-structure)
4. [Type Mapping Between C++ and Swift](#type-mapping-between-c-and-swift)
5. [How to Add a New C++ Function](#how-to-add-a-new-c-function)
6. [Performance Considerations](#performance-considerations)
7. [Debugging C++ Code from Swift](#debugging-c-code-from-swift)
8. [Build Settings Reference](#build-settings-reference)
9. [Troubleshooting](#troubleshooting)

---

## Overview

项目使用 **Swift 6 的原生 C++ 互操作性**，直接从 Swift 调用 C++ 函数，无需 Objective-C 桥接层。这被用于 `CppCore` 包中对性能要求极高的算法：

- **碰撞检测 (Collision detection)** -- AABB 重叠、圆与圆、圆与 AABB、点在框内
- **网格算法 (Grid algorithms)** -- 泛洪填充 (flood fill)、A* 路径规划、方块游戏的消除行检测
- **物理类型 (Physics types)** -- `Vec2`, `AABB`, `GridPos`

这些算法在热循环（每一帧）中运行，并受益于 C++ 的值语义和零成本抽象。

---

## Swift-C++ Interop Setup

Swift 6 支持通过 `.interoperabilityMode(.Cxx)` Swift 设置直接进行 C++ 互操作。不需要桥接头文件或 `@objc` 注解。

### Requirements

- Swift 6.1+ (swift-tools-version: 6.1)
- C++20 标准
- 在任何导入 C++ 代码的 Swift target 上开启 `.interoperabilityMode(.Cxx)` 设置

### How It Works

1. C++ 头文件通过 C++ target 中的 `publicHeadersPath` 暴露。
2. Swift 包装器 target 依赖于 C++ target 并启用 `.interoperabilityMode(.Cxx)`。
3. Swift 代码按名称导入 C++ 模块 (`import CppCore`) 并直接调用 C++ 函数。
4. Swift 编译器自动生成桥接——无需手动编写注解。

---

## CppCore Package Structure

```
Packages/CppCore/
├── Package.swift
├── Sources/
│   ├── CppCore/                      # C++ target
│   │   ├── include/                  # 公共头文件 (暴露给 Swift)
│   │   │   ├── CppCore.h            # 伞头文件 (Umbrella header)
│   │   │   ├── PhysicsTypes.h       # Vec2, AABB, GridPos
│   │   │   ├── CollisionDetection.h # 碰撞相关函数
│   │   │   └── GridAlgorithms.h     # 网格工具函数
│   │   └── src/                      # C++ 实现文件
│   │       ├── CollisionDetection.cpp
│   │       └── GridAlgorithms.cpp
│   └── CppCoreSwift/                 # Swift 包装器 target
│       └── CppCoreSwift.swift        # 为 Swift 使用者重新导出 CppCore
└── Tests/
    └── CppCoreTests/
        └── CppCoreTests.swift        # 测试 (同样使用 .interoperabilityMode(.Cxx))
```

### Package.swift Breakdown

```swift
// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "CppCore",
    platforms: [.iOS(.v26)],
    products: [
        // 公共产品是 Swift 包装器，而不是原始的 C++ target
        .library(name: "CppCore", targets: ["CppCoreSwift"])
    ],
    targets: [
        // 纯 C++ target -- 头文件 + 源文件
        .target(
            name: "CppCore",
            path: "Sources/CppCore",
            sources: ["src"],
            publicHeadersPath: "include",
            cxxSettings: [
                .headerSearchPath("include"),
                .unsafeFlags(["-std=c++20"])
            ]
        ),
        // 导入 C++ target 的 Swift 包装器
        .target(
            name: "CppCoreSwift",
            dependencies: ["CppCore"],
            path: "Sources/CppCoreSwift",
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        ),
        // 测试也需要 Cxx 互操作模式
        .testTarget(
            name: "CppCoreTests",
            dependencies: ["CppCoreSwift"],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        )
    ],
    cxxLanguageStandard: .cxx20
)
```

关键架构决策：
- **产品 (product)** 暴露的是 `CppCoreSwift`，而不是直接暴露 `CppCore`。下游的 Swift 包通过导入 `CppCoreSwift` 即可使用，无需自行启用 Cxx 互操作。
- `CppCoreSwift` target 使用 `public import CppCore` 来重新导出所有 C++ 符号。
- 在包层级设置 `cxxLanguageStandard: .cxx20` 确保了 C++ 标准的一致性。

---

## Type Mapping Between C++ and Swift

### PhysicsTypes.h Types

| C++ 类型 | Swift 访问方式 | 备注 |
|---|---|---|
| `cppcore::Vec2` | `CppCore.Vec2` | 值类型，字段为 `x: Float`, `y: Float` |
| `cppcore::AABB` | `CppCore.AABB` | 值类型，字段为 `min: Vec2`, `max: Vec2` |
| `cppcore::GridPos` | `CppCore.GridPos` | 值类型，字段为 `x: Int32`, `y: Int32` |

### Accessing C++ Types from Swift

```swift
import CppCore

// 直接构造 C++ 值类型
var position = cppcore.Vec2(x: 10.0, y: 20.0)
var box = cppcore.AABB(min: cppcore.Vec2(x: 0, y: 0),
                       max: cppcore.Vec2(x: 100, y: 100))
var gridPos = cppcore.GridPos(x: 5, y: 10)

// 调用方法
let lengthSq = position.lengthSquared()
let center = box.center()

// 运算符可以自然地工作
let sum = position + cppcore.Vec2(x: 1, y: 1)
let scaled = position * 2.0
```

### Standard Library Type Mapping

| C++ 类型 | Swift 类型 | 备注 |
|---|---|---|
| `int32_t` | `Int32` | 直接映射 |
| `float` | `Float` | 直接映射 |
| `bool` | `Bool` | 直接映射 |
| `std::vector<T>` | 导入为 C++ vector 类型 | 使用 `.size()`, 下标访问 |
| `std::string` | 导入为 C++ string 类型 | 需显式与 `String` 相互转换 |

### Working with std::vector

```swift
// C++ 函数返回 std::vector<GridPos>
let path = cppcore.aStarPath(grid, start, goal)

// 使用 C++ 语义进行迭代
for i in 0..<path.size() {
    let pos = path[i]
    print("Step: (\(pos.x), \(pos.y))")
}
```

---

## How to Add a New C++ Function

### Step 1: Declare the function in a header

在 `Sources/CppCore/include/` 中创建或编辑头文件：

```cpp
// include/NewAlgorithm.h
#ifndef NEW_ALGORITHM_H
#define NEW_ALGORITHM_H

#include "PhysicsTypes.h"
#include <vector>

namespace cppcore {

/// 简要描述该函数的功能。
/// @param input 输入参数描述。
/// @return 返回值描述。
float computeSomething(const Vec2& input, float threshold);

/// 另一个操作网格的函数。
std::vector<GridPos> findNeighbors(const std::vector<std::vector<int32_t>>& grid,
                                    GridPos center, int radius);

} // namespace cppcore

#endif // NEW_ALGORITHM_H
```

### Step 2: Implement in a .cpp file

在 `Sources/CppCore/src/` 中创建或编辑源文件：

```cpp
// src/NewAlgorithm.cpp
#include "NewAlgorithm.h"
#include <cmath>

namespace cppcore {

float computeSomething(const Vec2& input, float threshold) {
    float len = std::sqrt(input.lengthSquared());
    return len > threshold ? len : 0.0f;
}

std::vector<GridPos> findNeighbors(const std::vector<std::vector<int32_t>>& grid,
                                    GridPos center, int radius) {
    std::vector<GridPos> result;
    int rows = static_cast<int>(grid.size());
    if (rows == 0) return result;
    int cols = static_cast<int>(grid[0].size());

    for (int dy = -radius; dy <= radius; ++dy) {
        for (int dx = -radius; dx <= radius; ++dx) {
            int nx = center.x + dx;
            int ny = center.y + dy;
            if (nx >= 0 && nx < cols && ny >= 0 && ny < rows) {
                if (grid[ny][nx] != 0) {
                    result.push_back({static_cast<int32_t>(nx),
                                      static_cast<int32_t>(ny)});
                }
            }
        }
    }
    return result;
}

} // namespace cppcore
```

### Step 3: Include in umbrella header

编辑 `Sources/CppCore/include/CppCore.h` 以包含你的新头文件：

```cpp
#include "PhysicsTypes.h"
#include "CollisionDetection.h"
#include "GridAlgorithms.h"
#include "NewAlgorithm.h"    // <-- Add this line
```

### Step 4: Call from Swift

```swift
import CppCoreSwift  // 如果直接使用 Cxx 互操作，也可以 import CppCore

let input = cppcore.Vec2(x: 3.0, y: 4.0)
let result = cppcore.computeSomething(input, 2.0)
// result == 5.0
```

### Step 5: Write tests

```swift
// Tests/CppCoreTests/NewAlgorithmTests.swift
import Testing
@testable import CppCoreSwift
import CppCore

@Test func computeSomethingAboveThreshold() {
    let input = cppcore.Vec2(x: 3.0, y: 4.0)
    let result = cppcore.computeSomething(input, 2.0)
    #expect(abs(result - 5.0) < 0.001)
}

@Test func computeSomethingBelowThreshold() {
    let input = cppcore.Vec2(x: 0.5, y: 0.5)
    let result = cppcore.computeSomething(input, 2.0)
    #expect(result == 0.0)
}
```

---

## Performance Considerations

### Prefer Value Types

所有的 `CppCore` 类型 (`Vec2`, `AABB`, `GridPos`) 都是具有值语义的 C++ 结构体。Swift 将它们导入为值类型，这意味着：

- **无堆分配** -- 它们存在于栈上。
- **无引用计数** -- 没有 ARC 开销。
- **拷贝成本低** -- 它们体积很小 (8-16 字节)。

### Avoid Unnecessary Copies of Large Data

当向 C++ 函数传递 `std::vector` 时，优先使用 `const&` 参数以避免拷贝：

```cpp
// 推荐：常量引用，无拷贝
int clearCompletedRows(std::vector<std::vector<int32_t>>& grid);

// 避免：按值传递会强制进行拷贝
int clearCompletedRows(std::vector<std::vector<int32_t>> grid);
```

### Keep C++ Functions Pure When Possible

纯函数（无全局状态，无 I/O）具有以下优点：
- 易于测试
- 可以安全地从任何线程调用（对 Swift 的并发模型很重要）
- 有利于编译器优化（内联、向量化）

### Batch Operations

与其在 Swift 中对每个网格单元调用一次 C++ 函数，不如传递整个网格让 C++ 在内部进行迭代。虽然单次 Swift 到 C++ 的调用开销很小，但在紧密循环中累加起来也不容忽视。

```swift
// 推荐：单次调用，C++ 内部迭代
let clearedRows = cppcore.clearCompletedRows(&grid)

// 避免：在 Swift 中按单元格调用
for y in 0..<height {
    for x in 0..<width {
        cppcore.processCell(grid, x, y)  // N*M 次跨语言调用
    }
}
```

### Profile Before Optimizing

在将逻辑从 Swift 迁移到 C++ 之前，使用 Instruments (Time Profiler) 验证 C++ 代码路径是否确实是性能瓶颈。Swift 的优化器非常出色，许多算法在纯 Swift 中已经足够快了。

---

## Debugging C++ Code from Swift

### Xcode Debugger

Xcode 调试器 (LLDB) 可以单步跳入从 Swift 调用的 C++ 代码：

1. 在 Swift 代码的 C++ 调用处附近设置断点。
2. 使用“Step Into” (F7) 进入 C++ 函数。
3. 在“Variables View”中检查 C++ 变量——它们可以正确显示。
4. 使用 LLDB 控制台进行表达式求值：
   ```
   (lldb) expr position.x
   (float) $0 = 3.0
   (lldb) expr box.width()
   (float) $1 = 100.0
   ```

### Debug Build Settings

确保 Debug 构建使用 `-O0`（无优化）以获得可读的堆栈跟踪。Release 构建应使用 `-O2` 或 `-Os`。默认的 SPM/Xcode 配置会自动处理这些。

### Address Sanitizer

在 Xcode scheme 中启用 Address Sanitizer (ASan) 以捕获 C++ 代码中的内存错误：

1. Edit Scheme > Run > Diagnostics
2. 勾选 "Address Sanitizer"
3. 这可以捕获缓冲区溢出、use-after-free 以及其他内存漏洞。

### Common Debugging Patterns

```
(lldb) frame variable           # 显示所有本地变量
(lldb) expr grid.size()         # 执行 C++ 表达式
(lldb) bt                       # 显示 Swift 和 C++ 的完整回溯
(lldb) image lookup -a <addr>   # 查找地址对应的源代码位置
```

---

## Build Settings Reference

### Package-Level Settings

| 设置 | 值 | 用途 |
|---|---|---|
| `swift-tools-version` | `6.1` | Swift 6 Cxx 互操作所必须 |
| `cxxLanguageStandard` | `.cxx20` | 整个包使用 C++20 |

### C++ Target Settings (cxxSettings)

| 设置 | 值 | 用途 |
|---|---|---|
| `.headerSearchPath("include")` | -- | 允许 C++ 文件找到头文件 |
| `.unsafeFlags(["-std=c++20"])` | -- | 确保 target 使用 C++20 标准 |

### Swift Target Settings (swiftSettings)

| 设置 | 值 | 用途 |
|---|---|---|
| `.interoperabilityMode(.Cxx)` | -- | 在 Swift target 中启用 C++ 互操作 |

### Other Relevant Xcode Build Settings

如果通过 Xcode 项目（而不只是 SPM）进行构建：

| 设置 | 值 |
|---|---|
| `SWIFT_OBJC_INTEROP_MODE` | `objcxx` |
| `CLANG_CXX_LANGUAGE_STANDARD` | `c++20` |
| `CLANG_CXX_LIBRARY` | `libc++` |

---

## Troubleshooting

### "Cannot find 'cppcore' in scope"

确保 Swift target 的 `swiftSettings` 中包含 `.interoperabilityMode(.Cxx)`，并且该 target 依赖于 C++ target。

### "Use of undeclared identifier" in C++ headers

检查该头文件是否已包含在伞头文件 (`CppCore.h`) 中，并确保 `publicHeadersPath` 指向了正确的目录。

### Linker errors ("undefined symbol")

确保 `.cpp` 实现文件包含在 C++ target 的 `sources` 路径中。检查头文件和实现文件之间的命名空间和函数签名是否完全匹配。

### "Module 'CppCore' was not compiled with C++ interoperability"

使用该模块的 Swift target 必须开启 `.interoperabilityMode(.Cxx)`。如果你使用的是 `CppCoreSwift`（包装器），则不需要此设置——只有直接使用 `CppCore` C++ target 的使用者才需要。

### std::vector not working as expected

`std::vector` 虽然被导入，但并不遵循 Swift 的 `Collection` 协议。使用 `.size()` 获取计数，使用下标 `[i]` 进行访问。要转换为 Swift 数组，需显式迭代：

```swift
let cppPath = cppcore.aStarPath(grid, start, goal)
var swiftPath: [(x: Int32, y: Int32)] = []
for i in 0..<cppPath.size() {
    let pos = cppPath[i]
    swiftPath.append((pos.x, pos.y))
}
```
