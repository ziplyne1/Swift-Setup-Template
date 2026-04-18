// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "__PACKAGENAME__",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "__PACKAGENAME__",
            targets: ["__PACKAGENAME__"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "__PACKAGENAME__"
        ),
        .testTarget(
            name: "__PACKAGENAME__Tests",
            dependencies: ["__PACKAGENAME__"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
