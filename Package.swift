// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DockHider",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "DockHider", targets: ["DockHider"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "DockHider",
            dependencies: [],
            resources: [.process("Resources")]
        )
    ]
)
