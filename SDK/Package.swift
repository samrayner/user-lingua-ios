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
        .library(name: "UserLingua", targets: ["UserLingua"]),
        .library(name: "Core", targets: ["Core"]),
        .library(name: "SystemAPIAliases", targets: ["SystemAPIAliases"]),
        .library(name: "Macros", targets: ["Macros"]),
        .library(name: "Theme", targets: ["Theme"]),
        .library(name: "RootFeature", targets: ["RootFeature"]),
        .library(name: "SelectionFeature", targets: ["SelectionFeature"]),
        .library(name: "InspectionFeature", targets: ["InspectionFeature"]),
        .library(name: "RecognitionFeature", targets: ["RecognitionFeature"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-syntax", "509.0.0" ..< "511.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", .upToNextMinor(from: "1.9.2")),
        .package(url: "https://github.com/Matejkob/swift-spyable", .upToNextMinor(from: "0.3.0")),
        .package(url: "https://github.com/SFSafeSymbols/SFSafeSymbols", .upToNextMinor(from: "5.2.0")),
        .package(url: "https://github.com/gohanlon/swift-memberwise-init-macro", .upToNextMinor(from: "0.3.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "UserLingua",
            dependencies: [
                "Core",
                "SystemAPIAliases",
                "Macros",
                "RootFeature"
            ]
        ),
        .target(
            name: "Core",
            dependencies: [
                "Theme",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Spyable", package: "swift-spyable"),
                .product(name: "MemberwiseInit", package: "swift-memberwise-init-macro")
            ]
        ),
        .target(
            name: "Theme",
            dependencies: [
                .product(name: "SFSafeSymbols", package: "SFSafeSymbols")
            ],
            resources: [
                .process("Resources/Assets.xcassets")
            ]
        ),
        .target(
            name: "SystemAPIAliases",
            dependencies: []
        ),
        .target(
            name: "RootFeature",
            dependencies: [
                "Core",
                "SelectionFeature",
                "InspectionFeature"
            ]
        ),
        .target(
            name: "RecognitionFeature",
            dependencies: [
                "Core"
            ]
        ),
        .target(
            name: "SelectionFeature",
            dependencies: [
                "Core",
                "RecognitionFeature"
            ]
        ),
        .target(
            name: "InspectionFeature",
            dependencies: [
                "Core",
                "RecognitionFeature"
            ]
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

// for target in package.targets {
//  var settings = target.swiftSettings ?? []
//  settings.append(.enableExperimentalFeature("StrictConcurrency"))
//  target.swiftSettings = settings
// }
