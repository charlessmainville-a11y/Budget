// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PatternCore",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "PatternCore", targets: ["PatternCore"])
    ],
    targets: [
        .target(name: "PatternCore"),
        .testTarget(name: "PatternCoreTests", dependencies: ["PatternCore"])
    ]
)
