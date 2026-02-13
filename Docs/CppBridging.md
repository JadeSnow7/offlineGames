# C++ Bridging Guide

This document covers how C++ code is integrated into the project via Swift's native C++ interoperability, the `CppCore` package architecture, and how to add new C++ functionality.

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

The project uses **Swift 6's native C++ interoperability** to call C++ functions directly from Swift without an Objective-C bridging layer. This is used for performance-critical algorithms in the `CppCore` package:

- **Collision detection** -- AABB overlap, circle-circle, circle-AABB, point-in-box
- **Grid algorithms** -- flood fill, A* pathfinding, row clearing for block puzzles
- **Physics types** -- `Vec2`, `AABB`, `GridPos`

These algorithms run in hot loops (every tick) and benefit from C++ value semantics and zero-cost abstractions.

---

## Swift-C++ Interop Setup

Swift 6 supports direct C++ interop via the `.interoperabilityMode(.Cxx)` Swift setting. No bridging headers or `@objc` annotations are needed.

### Requirements

- Swift 6.1+ (swift-tools-version: 6.1)
- C++20 standard
- The `.interoperabilityMode(.Cxx)` setting on any Swift target that imports C++ code

### How It Works

1. C++ headers are exposed via `publicHeadersPath` in the C++ target.
2. A Swift wrapper target depends on the C++ target and enables `.interoperabilityMode(.Cxx)`.
3. Swift code imports the C++ module by name (`import CppCore`) and calls C++ functions directly.
4. The Swift compiler generates the bridging automatically -- no manual annotations needed.

---

## CppCore Package Structure

```
Packages/CppCore/
├── Package.swift
├── Sources/
│   ├── CppCore/                      # C++ target
│   │   ├── include/                  # Public headers (exposed to Swift)
│   │   │   ├── CppCore.h            # Umbrella header
│   │   │   ├── PhysicsTypes.h       # Vec2, AABB, GridPos
│   │   │   ├── CollisionDetection.h # Collision functions
│   │   │   └── GridAlgorithms.h     # Grid utility functions
│   │   └── src/                      # C++ implementations
│   │       ├── CollisionDetection.cpp
│   │       └── GridAlgorithms.cpp
│   └── CppCoreSwift/                 # Swift wrapper target
│       └── CppCoreSwift.swift        # Re-exports CppCore for Swift consumers
└── Tests/
    └── CppCoreTests/
        └── CppCoreTests.swift        # Tests (also uses .interoperabilityMode(.Cxx))
```

### Package.swift Breakdown

```swift
// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "CppCore",
    platforms: [.iOS(.v26)],
    products: [
        // The public product is the Swift wrapper, not the raw C++ target
        .library(name: "CppCore", targets: ["CppCoreSwift"])
    ],
    targets: [
        // Pure C++ target -- headers + source files
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
        // Swift wrapper that imports the C++ target
        .target(
            name: "CppCoreSwift",
            dependencies: ["CppCore"],
            path: "Sources/CppCoreSwift",
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        ),
        // Tests also need Cxx interop mode
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

Key architectural decisions:
- The **product** exposes `CppCoreSwift`, not `CppCore` directly. Downstream Swift packages import `CppCoreSwift` and do not need to enable Cxx interop themselves.
- The `CppCoreSwift` target uses `public import CppCore` to re-export all C++ symbols.
- The `cxxLanguageStandard: .cxx20` at the package level ensures consistent C++ standard.

---

## Type Mapping Between C++ and Swift

### PhysicsTypes.h Types

| C++ Type | Swift Access | Notes |
|---|---|---|
| `cppcore::Vec2` | `CppCore.Vec2` | Value type, fields `x: Float`, `y: Float` |
| `cppcore::AABB` | `CppCore.AABB` | Value type, fields `min: Vec2`, `max: Vec2` |
| `cppcore::GridPos` | `CppCore.GridPos` | Value type, fields `x: Int32`, `y: Int32` |

### Accessing C++ Types from Swift

```swift
import CppCore

// Construct C++ value types directly
var position = cppcore.Vec2(x: 10.0, y: 20.0)
var box = cppcore.AABB(min: cppcore.Vec2(x: 0, y: 0),
                       max: cppcore.Vec2(x: 100, y: 100))
var gridPos = cppcore.GridPos(x: 5, y: 10)

// Call methods
let lengthSq = position.lengthSquared()
let center = box.center()

// Operators work naturally
let sum = position + cppcore.Vec2(x: 1, y: 1)
let scaled = position * 2.0
```

### Standard Library Type Mapping

| C++ Type | Swift Type | Notes |
|---|---|---|
| `int32_t` | `Int32` | Direct mapping |
| `float` | `Float` | Direct mapping |
| `bool` | `Bool` | Direct mapping |
| `std::vector<T>` | Imported as C++ vector type | Use `.size()`, subscript access |
| `std::string` | Imported as C++ string type | Convert to/from `String` explicitly |

### Working with std::vector

```swift
// C++ function returns std::vector<GridPos>
let path = cppcore.aStarPath(grid, start, goal)

// Iterate using C++ semantics
for i in 0..<path.size() {
    let pos = path[i]
    print("Step: (\(pos.x), \(pos.y))")
}
```

---

## How to Add a New C++ Function

### Step 1: Declare the function in a header

Create or edit a header in `Sources/CppCore/include/`:

```cpp
// include/NewAlgorithm.h
#ifndef NEW_ALGORITHM_H
#define NEW_ALGORITHM_H

#include "PhysicsTypes.h"
#include <vector>

namespace cppcore {

/// Brief description of what this function does.
/// @param input Description of input parameter.
/// @return Description of return value.
float computeSomething(const Vec2& input, float threshold);

/// Another function that operates on grids.
std::vector<GridPos> findNeighbors(const std::vector<std::vector<int32_t>>& grid,
                                    GridPos center, int radius);

} // namespace cppcore

#endif // NEW_ALGORITHM_H
```

### Step 2: Implement in a .cpp file

Create or edit a source file in `Sources/CppCore/src/`:

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

Edit `Sources/CppCore/include/CppCore.h` to include your new header:

```cpp
#include "PhysicsTypes.h"
#include "CollisionDetection.h"
#include "GridAlgorithms.h"
#include "NewAlgorithm.h"    // <-- Add this line
```

### Step 4: Call from Swift

```swift
import CppCoreSwift  // or import CppCore if using Cxx interop directly

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

All `CppCore` types (`Vec2`, `AABB`, `GridPos`) are C++ structs with value semantics. Swift imports them as value types, which means:

- **No heap allocation** -- these live on the stack.
- **No reference counting** -- no ARC overhead.
- **Copy is cheap** -- they are small (8-16 bytes).

### Avoid Unnecessary Copies of Large Data

When passing `std::vector` to C++ functions, prefer `const&` parameters to avoid copies:

```cpp
// Good: const reference, no copy
int clearCompletedRows(std::vector<std::vector<int32_t>>& grid);

// Avoid: pass by value forces a copy
int clearCompletedRows(std::vector<std::vector<int32_t>> grid);
```

### Keep C++ Functions Pure When Possible

Pure functions (no global state, no I/O) are:
- Easier to test
- Safe to call from any thread (important for Swift's concurrency model)
- Eligible for compiler optimizations (inlining, vectorization)

### Batch Operations

Instead of calling a C++ function once per grid cell from Swift, pass the entire grid and let C++ iterate internally. The overhead of each Swift-to-C++ call is small but adds up in tight loops.

```swift
// Good: single call, C++ iterates internally
let clearedRows = cppcore.clearCompletedRows(&grid)

// Avoid: calling per-cell from Swift
for y in 0..<height {
    for x in 0..<width {
        cppcore.processCell(grid, x, y)  // N*M cross-language calls
    }
}
```

### Profile Before Optimizing

Use Instruments (Time Profiler) to verify that C++ code paths are actually hot before moving logic from Swift to C++. Swift's optimizer is excellent and many algorithms are fast enough in pure Swift.

---

## Debugging C++ Code from Swift

### Xcode Debugger

The Xcode debugger (LLDB) can step into C++ code called from Swift:

1. Set a breakpoint in Swift code near the C++ call.
2. Use "Step Into" (F7) to enter the C++ function.
3. Inspect C++ variables in the Variables View -- they display correctly.
4. Use the LLDB console for expression evaluation:
   ```
   (lldb) expr position.x
   (float) $0 = 3.0
   (lldb) expr box.width()
   (float) $1 = 100.0
   ```

### Debug Build Settings

Ensure debug builds use `-O0` (no optimization) for readable stack traces. Release builds should use `-O2` or `-Os`. The default SPM/Xcode configuration handles this automatically.

### Address Sanitizer

Enable Address Sanitizer (ASan) in the Xcode scheme to catch memory errors in C++ code:

1. Edit Scheme > Run > Diagnostics
2. Check "Address Sanitizer"
3. This catches buffer overflows, use-after-free, and other memory bugs.

### Common Debugging Patterns

```
(lldb) frame variable           # Show all local variables
(lldb) expr grid.size()         # Evaluate C++ expressions
(lldb) bt                       # Full backtrace through Swift and C++
(lldb) image lookup -a <addr>   # Find source location for an address
```

---

## Build Settings Reference

### Package-Level Settings

| Setting | Value | Purpose |
|---|---|---|
| `swift-tools-version` | `6.1` | Required for Swift 6 Cxx interop |
| `cxxLanguageStandard` | `.cxx20` | C++20 for the entire package |

### C++ Target Settings (cxxSettings)

| Setting | Value | Purpose |
|---|---|---|
| `.headerSearchPath("include")` | -- | Allows C++ files to find headers |
| `.unsafeFlags(["-std=c++20"])` | -- | Ensures C++20 standard for the target |

### Swift Target Settings (swiftSettings)

| Setting | Value | Purpose |
|---|---|---|
| `.interoperabilityMode(.Cxx)` | -- | Enables C++ interop in Swift target |

### Other Relevant Xcode Build Settings

If building via Xcode project (not just SPM):

| Setting | Value |
|---|---|
| `SWIFT_OBJC_INTEROP_MODE` | `objcxx` |
| `CLANG_CXX_LANGUAGE_STANDARD` | `c++20` |
| `CLANG_CXX_LIBRARY` | `libc++` |

---

## Troubleshooting

### "Cannot find 'cppcore' in scope"

Ensure the Swift target has `.interoperabilityMode(.Cxx)` in its `swiftSettings` and depends on the C++ target.

### "Use of undeclared identifier" in C++ headers

Check that the header is included in the umbrella header (`CppCore.h`) and that `publicHeadersPath` points to the correct directory.

### Linker errors ("undefined symbol")

Ensure the `.cpp` implementation file is in the `sources` path of the C++ target. Check that the namespace and function signatures match exactly between the header and implementation.

### "Module 'CppCore' was not compiled with C++ interoperability"

The consuming Swift target must have `.interoperabilityMode(.Cxx)`. If you are consuming `CppCoreSwift` (the wrapper), you do not need this setting -- only direct consumers of the `CppCore` C++ target need it.

### std::vector not working as expected

`std::vector` is imported but does not conform to Swift's `Collection` protocol. Use `.size()` for count and subscript `[i]` for access. To convert to a Swift array, iterate explicitly:

```swift
let cppPath = cppcore.aStarPath(grid, start, goal)
var swiftPath: [(x: Int32, y: Int32)] = []
for i in 0..<cppPath.size() {
    let pos = cppPath[i]
    swiftPath.append((pos.x, pos.y))
}
```
