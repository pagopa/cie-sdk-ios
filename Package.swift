// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CieSDK",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CieSDK",
            targets: ["CieSDK"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/async-http-client.git", revision: "333f51104b75d1a5b94cb3b99e4c58a3b442c9f7"), // -> "1.25.2"
        .package(url: "https://github.com/apple/swift-asn1.git", revision: "ae33e5941bb88d88538d0a6b19ca0b01e6c76dcf"), // -> "1.3.1"
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "CieSDK",
            dependencies: [
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "SwiftASN1", package: "swift-asn1")
            ],
            path: "Sources"
        ),

    ]
)
