// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UserSpec",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "UserSpec",
            targets: ["UserSpec"]
        ),
    ],
    targets: [
        .target(
            name: "UserSpec"
        ),
        .testTarget(
            name: "UserSpecTests",
            dependencies: ["UserSpec"]
        ),
    ]
)
