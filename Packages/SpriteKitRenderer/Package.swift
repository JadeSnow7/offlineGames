// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SpriteKitRenderer",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "SpriteKitRenderer", targets: ["SpriteKitRenderer"])
    ],
    dependencies: [
        .package(path: "../CoreEngine")
    ],
    targets: [
        .target(
            name: "SpriteKitRenderer",
            dependencies: ["CoreEngine"]
        ),
        .testTarget(
            name: "SpriteKitRendererTests",
            dependencies: ["SpriteKitRenderer"]
        )
    ]
)
