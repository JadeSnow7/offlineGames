// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CoreEngine",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "CoreEngine", targets: ["CoreEngine"])
    ],
    targets: [
        .target(name: "CoreEngine"),
        .testTarget(name: "CoreEngineTests", dependencies: ["CoreEngine"])
    ]
)
