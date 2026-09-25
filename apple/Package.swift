// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PixelmeshCore",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "PixelmeshCore",
            targets: ["PixelmeshCore"]
        ),
        .executable(
            name: "PixelmeshCoreTestsRunner",
            targets: ["PixelmeshCoreTestsRunner"]
        )
    ],
    targets: [
        .target(
            name: "PixelmeshCore",
            dependencies: [],
            path: "Sources/PixelmeshCore"
        ),
        .executableTarget(
            name: "PixelmeshCoreTestsRunner",
            dependencies: ["PixelmeshCore"],
            path: "Sources/PixelmeshCoreTestsRunner"
        )
    ]
)
