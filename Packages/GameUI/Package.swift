// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "GameUI",
    defaultLocalization: "en",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "GameUI", targets: ["GameUI"])
    ],
    dependencies: [
        .package(path: "../CoreEngine"),
        .package(path: "../GameCatalog")
    ],
    targets: [
        .target(
            name: "GameUI",
            dependencies: ["CoreEngine", "GameCatalog"],
            resources: [
                .process("Resources/en.lproj"),
                .process("Resources/zh-Hans.lproj")
            ]
        ),
        .testTarget(
            name: "GameUITests",
            dependencies: ["GameUI"]
        )
    ]
)
