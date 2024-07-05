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
        .library(name: "UserLinguaMacros", targets: ["UserLinguaMacros"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: "https://github.com/apple/swift-syntax", "509.0.0" ..< "511.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "UserLingua",
            dependencies: [
                "UserLinguaCore"
            ]
        ),
        .target(
            name: "UserLinguaCore",
            dependencies: [],
            resources: [
                .copy("Resources/PrivacyInfo.xcprivacy"),
                .copy("Resources/Base.lproj"),
                .copy("Resources/Assets.xcassets")
            ]
        ),
        .target(
            name: "UserLinguaMacros",
            dependencies: [
                "UserLinguaExternalMacros"
            ]
        ),
        .macro(
            name: "UserLinguaExternalMacros",
            dependencies: [
                // .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                // .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        )
    ]
)

// for target in package.targets {
//  var settings = target.swiftSettings ?? []
//  settings.append(.enableExperimentalFeature("StrictConcurrency"))
//  target.swiftSettings = settings
// }
