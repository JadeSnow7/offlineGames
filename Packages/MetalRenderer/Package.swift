// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MetalRenderer",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "MetalRenderer", targets: ["MetalRenderer"])
    ],
    dependencies: [
        .package(path: "../CoreEngine")
    ],
    targets: [
        .target(
            name: "MetalRenderer",
            dependencies: ["CoreEngine"],
            resources: [.process("Shaders.metal")]
        ),
        .testTarget(
            name: "MetalRendererTests",
            dependencies: ["MetalRenderer"]
        )
    ]
)
