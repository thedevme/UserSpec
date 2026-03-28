// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "UserSpecExamples",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    dependencies: [
        .package(path: "../.."),
    ],
    targets: [
        .target(
            name: "UserSpecExamples",
            path: "Sources"
        ),
        .testTarget(
            name: "UserSpecExamplesTests",
            dependencies: [
                "UserSpecExamples",
                .product(name: "UserSpec", package: "UserSpec")
            ],
            path: "Tests"
        ),
    ]
)
