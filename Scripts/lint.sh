#!/bin/bash
# Run SwiftLint on all Swift source files.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v swiftlint &> /dev/null; then
    echo "SwiftLint not installed. Install via: brew install swiftlint"
    exit 1
fi

echo "=== Running SwiftLint ==="
swiftlint lint --config "$ROOT_DIR/.swiftlint.yml" --path "$ROOT_DIR/Packages" --path "$ROOT_DIR/App"
echo "=== SwiftLint complete ==="
