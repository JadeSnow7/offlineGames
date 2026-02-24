// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SnakeGame",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "SnakeGame", targets: ["SnakeGame"])
    ],
    dependencies: [
        .package(path: "../CoreEngine"),
        .package(path: "../GameUI"),
        .package(path: "../GameCatalog")
    ],
    targets: [
        .target(
            name: "SnakeGame",
            dependencies: ["CoreEngine", "GameUI", "GameCatalog"]
        ),
        .testTarget(
            name: "SnakeGameTests",
            dependencies: ["SnakeGame"]
        )
    ]
)
