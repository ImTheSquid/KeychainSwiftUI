// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KeychainSwiftUI",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "KeychainSwiftUI",
            targets: ["KeychainSwiftUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/evgenyneu/keychain-swift", .upToNextMajor(from: "24.0.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "KeychainSwiftUI", dependencies: [.product(name: "KeychainSwift", package: "keychain-swift")]),
        .testTarget(
            name: "KeychainSwiftUITests",
            dependencies: ["KeychainSwiftUI"]
        ),
    ]

)
