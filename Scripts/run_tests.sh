#!/bin/bash
# Run tests for all SPM packages.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PACKAGES_DIR="$ROOT_DIR/Packages"

echo "=== Running tests for all packages ==="

# Packages that can be tested with swift test (pure Swift, no device-only frameworks)
TESTABLE_PACKAGES=(
    "CoreEngine"
    "GameCatalog"
    "CppCore"
)

PASS=0
FAIL=0

for pkg in "${TESTABLE_PACKAGES[@]}"; do
    PKG_PATH="$PACKAGES_DIR/$pkg"
    if [ -d "$PKG_PATH" ]; then
        echo ""
        echo "--- Testing $pkg ---"
        if swift test --package-path "$PKG_PATH" 2>&1; then
            echo "  PASS: $pkg"
            PASS=$((PASS + 1))
        else
            echo "  FAIL: $pkg"
            FAIL=$((FAIL + 1))
        fi
    fi
done

echo ""
echo "=== Test Summary ==="
echo "  Passed: $PASS"
echo "  Failed: $FAIL"

# Packages requiring iOS simulator (Metal, SpriteKit, UIKit, SwiftUI)
echo ""
echo "=== Skipped (require iOS Simulator — use Xcode) ==="
SIMULATOR_PACKAGES=(
    "MetalRenderer"
    "SpriteKitRenderer"
    "GameUI"
    "SnakeGame"
    "BlockPuzzle"
    "BreakoutGame"
    "MinesweeperGame"
    "MemoryMatch"
    "ReactionTap"
)
for pkg in "${SIMULATOR_PACKAGES[@]}"; do
    echo "  - $pkg"
done

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
