// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MemoryMatch",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "MemoryMatch", targets: ["MemoryMatch"])
    ],
    dependencies: [
        .package(path: "../CoreEngine"),
        .package(path: "../GameUI"),
        .package(path: "../GameCatalog")
    ],
    targets: [
        .target(
            name: "MemoryMatch",
            dependencies: ["CoreEngine", "GameUI", "GameCatalog"]
        ),
        .testTarget(
            name: "MemoryMatchTests",
            dependencies: ["MemoryMatch"]
        )
    ]
)
