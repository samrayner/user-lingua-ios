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
        .library(name: "UserLingua", targets: ["UserLingua"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-syntax", "509.0.0" ..< "511.0.0"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.2")
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
            ],
            resources: [
                .copy("Resources/PrivacyInfo.xcprivacy")
            ]
        ),
        .target(
            name: "Core",
            dependencies: [
                "ComposableArchitecture",
                "ComposableArchitectureMacros"
            ]
        ),
        .target(
            name: "Theme",
            dependencies: [],
            resources: [
                .process("Resources/Assets.xcassets")
            ]
        ),
        .target(
            name: "Strings",
            dependencies: []
        ),
        .target(
            name: "SystemAPIAliases",
            dependencies: []
        ),
        .target(
            name: "Diff",
            dependencies: [
                "KSSDiff"
            ]
        ),
        .target(
            name: "RootFeature",
            dependencies: [
                "Core",
                "Theme",
                "SelectionFeature"
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
                "Strings",
                "Theme",
                "RecognitionFeature",
                "InspectionFeature"
            ]
        ),
        .target(
            name: "InspectionFeature",
            dependencies: [
                "Core",
                "Strings",
                "Theme",
                "RecognitionFeature",
                "Diff"
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
        ),
        // BEGIN COPIED THIRD PARTY DEPENDENCIES
        .target(
            name: "KSSDiff",
            dependencies: []
        ),
        .target(
            name: "ComposableArchitecture",
            dependencies: [
                "ComposableArchitectureMacros",
                "CasePaths",
                "CombineSchedulers",
                "ConcurrencyExtras",
                "CustomDump",
                "Dependencies",
                "IdentifiedCollections",
                "Perception",
                "SwiftUINavigationCore",
                "XCTestDynamicOverlay",
                .product(name: "OrderedCollections", package: "swift-collections")
            ]
        ),
        .macro(
            name: "ComposableArchitectureMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(
            name: "Perception",
            dependencies: [
                "PerceptionMacros",
                "XCTestDynamicOverlay"
            ]
        ),
        .macro(
            name: "PerceptionMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(
            name: "SwiftUINavigation",
            dependencies: [
                "CasePaths"
            ]
        ),
        .target(
            name: "SwiftUINavigationCore",
            dependencies: [
                "CustomDump",
                "XCTestDynamicOverlay"
            ]
        ),
        .target(
            name: "CustomDump",
            dependencies: [
                "XCTestDynamicOverlay"
            ]
        ),
        .target(
            name: "Dependencies",
            dependencies: [
                "Clocks",
                "CombineSchedulers",
                "ConcurrencyExtras"
            ]
        ),
        .target(
            name: "Clocks",
            dependencies: [
                "XCTestDynamicOverlay",
                "ConcurrencyExtras"
            ]
        ),
        .target(
            name: "CasePaths",
            dependencies: [
                "CasePathsMacros",
                "XCTestDynamicOverlay"
            ]
        ),
        .macro(
            name: "CasePathsMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(
            name: "CombineSchedulers",
            dependencies: [
                "XCTestDynamicOverlay"
            ]
        ),
        .target(
            name: "XCTestDynamicOverlay",
            dependencies: [
                "ConcurrencyExtras"
            ]
        ),
        .target(
            name: "ConcurrencyExtras",
            dependencies: []
        ),
        .target(
            name: "IdentifiedCollections",
            dependencies: [
                .product(name: "OrderedCollections", package: "swift-collections")
            ]
        )
        // END COPIED THIRD PARTY DEPENDENCIES
    ]
)

// for target in package.targets {
//  var settings = target.swiftSettings ?? []
//  settings.append(.enableExperimentalFeature("StrictConcurrency"))
//  target.swiftSettings = settings
// }
