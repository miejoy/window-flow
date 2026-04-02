// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "window-flow",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8),
    ],
    products: [
        .library(
            name: "WindowFlow",
            targets: ["WindowFlow"]),
    ],
    dependencies: [
        .package(url: "https://github.com/miejoy/data-flow.git", branch: "main"),
        .package(url: "https://github.com/miejoy/view-flow.git", branch: "main"),
        .package(url: "https://github.com/miejoy/logger.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "WindowFlow",
            dependencies: [
                .product(name: "DataFlow", package: "data-flow"),
                .product(name: "ViewFlow", package: "view-flow"),
                .product(name: "Logger", package: "logger"),
            ]
        ),
        .testTarget(
            name: "WindowFlowTests",
            dependencies: [
                "WindowFlow",
                .product(name: "DataFlow", package: "data-flow"),
                .product(name: "ViewFlow", package: "view-flow"),
            ]
        ),
    ]
)
