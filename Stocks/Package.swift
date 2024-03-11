// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Stocks",
    platforms: [.macOS(.v13),.iOS(.v16),.macCatalyst(.v16),.tvOS(.v16)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Stocks",
            targets: ["Stocks"]),
        .library(
            name: "PolygonAPI",
            targets: ["PolygonAPI"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Stocks",
            dependencies: ["PolygonAPI"]),
        .target(
            name: "PolygonAPI"),
        .testTarget(
            name: "StocksTests",
            dependencies: ["Stocks"]),
        .testTarget(
            name: "PolygonAPITests",
            dependencies: ["PolygonAPI"]),
    ]
)
