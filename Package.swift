// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftKafka",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftKafka",
            targets: ["SwiftKafka"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.2")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .systemLibrary(
            name: "rdkafka",
            pkgConfig: "rdkafka",
            providers: [.brew(["librdkafka"]), .apt(["librdkafka-dev"])]),
        .target(
            name: "SwiftKafka",
            dependencies: ["rdkafka", .product(name: "Logging", package: "swift-log")]
        ),
        .testTarget(
            name: "SwiftKafkaTests",
            dependencies: ["SwiftKafka"]),
    ]
)
