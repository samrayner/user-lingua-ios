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
        .library(name: "UserLinguaCore", targets: ["UserLinguaCore"]),
        .library(name: "UserLinguaAuto", targets: ["UserLinguaAuto"]),
        .library(name: "UserLinguaMacros", targets: ["UserLinguaMacros"]),
        .library(name: "RootFeature", targets: ["RootFeature"]),
        .library(name: "RecognitionFeature", targets: ["RecognitionFeature"]),
        .library(name: "SelectionFeature", targets: ["SelectionFeature"]),
        .library(name: "InspectionFeature", targets: ["InspectionFeature"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-syntax", "509.0.0" ..< "511.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "UserLingua",
            dependencies: [
                "UserLinguaCore",
                "UserLinguaAuto",
                "UserLinguaMacros"
            ]
        ),
        .target(
            name: "UserLinguaCore",
            dependencies: [
                "Services",
                "Repositories",
                "Models",
                "Utilities",
                "RootFeature"
            ]
        ),
        .target(
            name: "UserLinguaAuto",
            dependencies: [
                "UserLinguaCore"
            ]
        ),
        .target(
            name: "UserLinguaMacros",
            dependencies: [
                "UserLinguaExternalMacros"
            ]
        ),
        .target(
            name: "Utilities",
            dependencies: []
        ),
        .target(
            name: "AnyCodable",
            dependencies: []
        ),
        .target(
            name: "CodableCVarArg",
            dependencies: []
        ),
        .target(
            name: "Models",
            dependencies: [
                "Utilities",
                "AnyCodable",
                "CodableCVarArg"
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
            name: "Services",
            dependencies: [
                "Models",
                "Utilities"
            ]
        ),
        .target(
            name: "Persistence",
            dependencies: [
                "Models",
                "Utilities",
                "GRDB"
            ]
        ),
        .target(
            name: "Repositories",
            dependencies: [
                "Models",
                "Utilities"
            ]
        ),
        .target(
            name: "GRDB"
        ),
        .target(
            name: "Diff",
            dependencies: [
                "KSSDiff"
            ]
        ),
        .target(
            name: "KSSDiff",
            dependencies: []
        ),
        .target(
            name: "CasePaths",
            dependencies: [
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
            name: "XCTestDynamicOverlay",
            dependencies: []
        ),
        .target(
            name: "CombineSchedulers",
            dependencies: [
                "XCTestDynamicOverlay"
            ]
        ),
        .target(
            name: "CombineFeedback",
            dependencies: [
                "CasePaths",
                "CombineSchedulers",
                "CustomDump",
                "Utilities"
            ]
        ),
        .target(
            name: "RootFeature",
            dependencies: [
                "CombineFeedback",
                "Services",
                "Repositories",
                "Models",
                "Utilities",
                "Theme",
                "SelectionFeature"
            ]
        ),
        .target(
            name: "RecognitionFeature",
            dependencies: [
                "CombineFeedback",
                "Services",
                "Models",
                "Utilities"
            ]
        ),
        .target(
            name: "SelectionFeature",
            dependencies: [
                "CombineFeedback",
                "Services",
                "Models",
                "Utilities",
                "Strings",
                "Theme",
                "RecognitionFeature",
                "InspectionFeature"
            ]
        ),
        .target(
            name: "InspectionFeature",
            dependencies: [
                "CombineFeedback",
                "Services",
                "Repositories",
                "Models",
                "Utilities",
                "Strings",
                "Theme",
                "RecognitionFeature",
                "Diff"
            ]
        ),
        .testTarget(
            name: "UserLinguaTests",
            dependencies: [
                "UserLinguaCore",
                "UserLinguaMacros",
                .product(
                    name: "SwiftSyntaxMacrosTestSupport",
                    package: "swift-syntax"
                )
            ]
        ),
        .macro(
            name: "UserLinguaExternalMacros",
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
