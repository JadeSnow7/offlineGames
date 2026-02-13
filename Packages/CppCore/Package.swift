// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CppCore",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "CppCore", targets: ["CppCoreSwift"])
    ],
    targets: [
        .target(
            name: "CppCore",
            path: "Sources/CppCore",
            sources: ["src"],
            publicHeadersPath: "include",
            cxxSettings: [
                .headerSearchPath("include"),
                .unsafeFlags(["-std=c++20"])
            ]
        ),
        .target(
            name: "CppCoreSwift",
            dependencies: ["CppCore"],
            path: "Sources/CppCoreSwift",
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        ),
        .testTarget(
            name: "CppCoreTests",
            dependencies: ["CppCoreSwift"],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        )
    ],
    cxxLanguageStandard: .cxx20
)
