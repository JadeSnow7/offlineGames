// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "BreakoutGame",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "BreakoutGame", targets: ["BreakoutGame"])
    ],
    dependencies: [
        .package(path: "../CoreEngine"),
        .package(path: "../GameUI")
    ],
    targets: [
        .target(
            name: "BreakoutGame",
            dependencies: ["CoreEngine", "GameUI"]
        ),
        .testTarget(
            name: "BreakoutGameTests",
            dependencies: ["BreakoutGame"]
        )
    ]
)
