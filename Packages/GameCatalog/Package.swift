// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "GameCatalog",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "GameCatalog", targets: ["GameCatalog"])
    ],
    dependencies: [
        .package(path: "../CoreEngine")
    ],
    targets: [
        .target(
            name: "GameCatalog",
            dependencies: ["CoreEngine"]
        ),
        .testTarget(
            name: "GameCatalogTests",
            dependencies: ["GameCatalog"]
        )
    ]
)
