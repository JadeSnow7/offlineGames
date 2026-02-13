// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "GameUI",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "GameUI", targets: ["GameUI"])
    ],
    dependencies: [
        .package(path: "../CoreEngine")
    ],
    targets: [
        .target(
            name: "GameUI",
            dependencies: ["CoreEngine"]
        ),
        .testTarget(
            name: "GameUITests",
            dependencies: ["GameUI"]
        )
    ]
)
