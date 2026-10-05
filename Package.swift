// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CloudflareSwitcher",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "CloudflareSwitcher",
            targets: ["CloudflareSwitcher"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "CloudflareSwitcher",
            dependencies: [],
            path: "Sources/CloudflareSwitcher"
        )
    ]
)
