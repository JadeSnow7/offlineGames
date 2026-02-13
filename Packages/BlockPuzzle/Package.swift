// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "BlockPuzzle",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "BlockPuzzle", targets: ["BlockPuzzle"])
    ],
    dependencies: [
        .package(path: "../CoreEngine"),
        .package(path: "../GameUI")
    ],
    targets: [
        .target(
            name: "BlockPuzzle",
            dependencies: ["CoreEngine", "GameUI"]
        ),
        .testTarget(
            name: "BlockPuzzleTests",
            dependencies: ["BlockPuzzle"]
        )
    ]
)
