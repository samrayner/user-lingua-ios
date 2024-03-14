// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "UserLingua",
    defaultLocalization: "en",
    platforms: [.iOS(.v16), .macOS(.v10_15)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "UserLingua",
            targets: ["UserLingua", "SystemAPIAliases"]
        )
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-syntax", "509.0.0" ..< "511.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", .upToNextMinor(from: "1.9.2")),
        .package(url: "https://github.com/Matejkob/swift-spyable", .upToNextMinor(from: "0.3.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "UserLingua",
            dependencies: [
                "SystemAPIAliases",
                "Macros",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Spyable", package: "swift-spyable")
            ],
            resources: [
                .process("Resources/Assets.xcassets")
            ]
        ),
        .target(
            name: "SystemAPIAliases",
            dependencies: []
        ),
        .testTarget(
            name: "UserLinguaTests",
            dependencies: [
                "UserLingua",
                "Macros",
                .product(
                    name: "SwiftSyntaxMacrosTestSupport",
                    package: "swift-syntax"
                )
            ]
        ),
        .macro(
            name: "Macros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        )
    ]
)
