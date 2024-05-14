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
                "Lib_ComposableArchitecture"
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
                "Lib_KSSDiff"
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
        .target(
            name: "Lib_KSSDiff",
            dependencies: []
        ),
        .target(
            name: "Lib_ComposableArchitecture",
            dependencies: [
                "Lib_CasePaths",
                "Lib_CombineSchedulers",
                "Lib_ConcurrencyExtras",
                "Lib_CustomDump",
                "Lib_Dependencies",
                "Lib_IdentifiedCollections",
                "Lib_SwiftUINavigationCore",
                "Lib_XCTestDynamicOverlay",
                .product(name: "OrderedCollections", package: "swift-collections")
            ]
        ),
        .target(
            name: "Lib_SwiftUINavigation",
            dependencies: [
                "Lib_CasePaths"
            ]
        ),
        .target(
            name: "Lib_SwiftUINavigationCore",
            dependencies: [
                "Lib_CustomDump",
                "Lib_XCTestDynamicOverlay"
            ]
        ),
        .target(
            name: "Lib_CustomDump",
            dependencies: [
                "Lib_XCTestDynamicOverlay"
            ]
        ),
        .target(
            name: "Lib_Dependencies",
            dependencies: [
                "Lib_Clocks",
                "Lib_CombineSchedulers",
                "Lib_ConcurrencyExtras"
            ]
        ),
        .target(
            name: "Lib_Clocks",
            dependencies: [
                "Lib_XCTestDynamicOverlay",
                "Lib_ConcurrencyExtras"
            ]
        ),
        .target(
            name: "Lib_CasePaths",
            dependencies: [
                "Lib_XCTestDynamicOverlay"
            ]
        ),
        .target(
            name: "Lib_CombineSchedulers",
            dependencies: [
                "Lib_XCTestDynamicOverlay"
            ]
        ),
        .target(
            name: "Lib_XCTestDynamicOverlay",
            dependencies: [
                "Lib_ConcurrencyExtras"
            ]
        ),
        .target(
            name: "Lib_ConcurrencyExtras",
            dependencies: []
        ),
        .target(
            name: "Lib_IdentifiedCollections",
            dependencies: [
                .product(name: "OrderedCollections", package: "swift-collections")
            ]
        )
    ]
)

// for target in package.targets {
//  var settings = target.swiftSettings ?? []
//  settings.append(.enableExperimentalFeature("StrictConcurrency"))
//  target.swiftSettings = settings
// }
