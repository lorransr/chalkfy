// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Chalkfy",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "Core"),
        .executableTarget(name: "Chalkfy", dependencies: ["Core"]),
        .testTarget(name: "CoreTests", dependencies: ["Core"]),
    ]
)
