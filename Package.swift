// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WorldClockMenuBar",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "WorldClockMenuBarCore",
            path: "Sources/WorldClockMenuBarCore"
        ),
        .executableTarget(
            name: "WorldClockMenuBar",
            dependencies: ["WorldClockMenuBarCore"],
            path: "Sources/WorldClockMenuBar"
        ),
        .testTarget(
            name: "WorldClockMenuBarCoreTests",
            dependencies: ["WorldClockMenuBarCore"],
            path: "Tests/WorldClockMenuBarCoreTests"
        ),
    ]
)
