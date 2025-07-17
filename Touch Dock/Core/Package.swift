// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "TouchDock",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(name: "TouchDock", targets: ["TouchDock"])
    ],
    dependencies: [
        .package(url: "https://github.com/shpakovski/MASShortcut.git", from: "1.4.2")
    ],
    targets: [
        .executableTarget(
            name: "TouchDock",
            dependencies: ["MASShortcut"],
            path: "Sources",
            resources: [.copy("../Resources")]
        ),
        .testTarget(
            name: "TouchDockTests",
            dependencies: ["TouchDock"],
            path: "Tests"
        )
    ]
)
