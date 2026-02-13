// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ReactionTap",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "ReactionTap", targets: ["ReactionTap"])
    ],
    dependencies: [
        .package(path: "../CoreEngine"),
        .package(path: "../GameUI")
    ],
    targets: [
        .target(
            name: "ReactionTap",
            dependencies: ["CoreEngine", "GameUI"]
        ),
        .testTarget(
            name: "ReactionTapTests",
            dependencies: ["ReactionTap"]
        )
    ]
)
