// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CardDuel",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "CardDuel", targets: ["CardDuel"])
    ],
    dependencies: [
        .package(path: "../CoreEngine"),
        .package(path: "../GameUI"),
        .package(path: "../GameCatalog")
    ],
    targets: [
        .target(
            name: "CardDuel",
            dependencies: ["CoreEngine", "GameUI", "GameCatalog"]
        ),
        .testTarget(
            name: "CardDuelTests",
            dependencies: ["CardDuel"]
        )
    ]
)
