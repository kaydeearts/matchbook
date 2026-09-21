// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "matchbook",
    platforms: [.macOS(.v13)],
    products: [
        // Core engine — order book + matching logic. Pure, testable, no I/O.
        .library(name: "MatchingEngine", targets: ["MatchingEngine"]),
        // Driver / server executable. Phase 1: a scripted driver. Phase 3: the Network.framework server.
        .executable(name: "matchbook", targets: ["matchbook"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),
    ],
    targets: [
        .target(
            name: "MatchingEngine",
            dependencies: [
                .product(name: "Collections", package: "swift-collections"),
            ]
        ),
        .executableTarget(
            name: "matchbook",
            dependencies: ["MatchingEngine"]
        ),
        .testTarget(
            name: "MatchingEngineTests",
            dependencies: ["MatchingEngine"]
        ),
    ]
)
