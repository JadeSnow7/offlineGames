// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MinesweeperGame",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "MinesweeperGame", targets: ["MinesweeperGame"])
    ],
    dependencies: [
        .package(path: "../CoreEngine"),
        .package(path: "../GameUI"),
        .package(path: "../GameCatalog")
    ],
    targets: [
        .target(
            name: "MinesweeperGame",
            dependencies: ["CoreEngine", "GameUI", "GameCatalog"]
        ),
        .testTarget(
            name: "MinesweeperGameTests",
            dependencies: ["MinesweeperGame"]
        )
    ]
)
