// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "Discogs",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "Discogs",
            targets: ["Discogs"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "Discogs"
        ),
        .testTarget(
            name: "DiscogsTests",
            dependencies: ["Discogs"]
        ),
    ]
)
