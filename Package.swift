// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Twenty20",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "Twenty20",
            path: "Sources/Twenty20"
        ),
        .testTarget(
            name: "Twenty20Tests",
            dependencies: ["Twenty20"],
            path: "Tests/Twenty20Tests"
        )
    ]
)
