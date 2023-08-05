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
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.2"),
        .package(url: "https://github.com/facebook/zstd.git", from: "1.5.5"),
    ],
    targets: [
        .target(
            name: "RdKafka",
            dependencies: [
                "OpenSSL",
                .product(name: "libzstd", package: "zstd"),
            ],
            exclude: [
                "librdkafka/src/CMakeLists.txt",
                "librdkafka/src/statistics_schema.json",
                "librdkafka/src/Makefile",
                "librdkafka/src/generate_proto.sh",
                "librdkafka/src/librdkafka_cgrp_synch.png",
                "./librdkafka/src/rdkafka_sasl_win32.c",
            ],
            sources: ["./librdkafka/src"],
            publicHeadersPath: "./include",
            cSettings: [
                .headerSearchPath("./librdkafka/src"),
                .headerSearchPath("./config/dummy"),
            ],
            linkerSettings: [
                .linkedLibrary("curl"),
                .linkedLibrary("z"),
                .linkedLibrary("sasl2"),
            ]
        ),
        .systemLibrary(
            name: "OpenSSL",
            pkgConfig: "openssl",
            providers: [
                .brew(["libressl"]),
                .apt(["libssl-dev"]),
            ]
        ),
        .target(
            name: "SwiftKafka",
            dependencies: [
                "RdKafka",
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        .testTarget(
            name: "SwiftKafkaTests",
            dependencies: [
                "SwiftKafka",
                "RdKafka"
            ]),
    ]
)
