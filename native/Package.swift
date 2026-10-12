// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "REyeTCCalkCore",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "REyeTCCalkCore", targets: ["REyeTCCalkCore"])
    ],
    targets: [
        .target(name: "REyeTCCalkCore"),
        .testTarget(
            name: "REyeTCCalkCoreTests",
            dependencies: ["REyeTCCalkCore"]
        )
    ]
)
