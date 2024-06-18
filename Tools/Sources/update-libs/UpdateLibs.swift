// UpdateLibs.swift

import ArgumentParser
import Foundation
import Zip

private struct Library: Hashable {
    let repoURL: URL
    let version: String

    static func package(
        url: String,
        exact version: String
    ) -> Self {
        .init(
            repoURL: URL(string: url)!,
            version: version
        )
    }

    var zipURL: URL {
        URL(string: "\(repoURL)/archive/refs/tags/\(version).zip")!
    }
}

@main
struct UpdateLibs: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Download, move and rename SDK dependencies.")

    var fileManager: FileManager { FileManager.default }
    var currentDir: URL { URL(fileURLWithPath: fileManager.currentDirectoryPath) }

    private func downloadLibrary(_ library: Library) async throws -> URL {
        let (data, _) = try await URLSession.shared.data(from: library.zipURL)

        let tempDir = NSURL.fileURL(withPath: NSTemporaryDirectory(), isDirectory: true)

        let zipFile = tempDir.appendingPathComponent("\(library.repoURL.lastPathComponent).zip")

        try data.write(to: zipFile)

        let unzippedDir = tempDir.appendingPathComponent(UUID().uuidString)

        try Zip.unzipFile(
            zipFile,
            destination: unzippedDir,
            overwrite: true,
            password: nil
        )

        return unzippedDir
    }

    private func editSwiftFiles(at url: URL, edit: (inout String) -> Void) throws {
        let fileURLs = fileManager
            .enumerator(at: url, includingPropertiesForKeys: nil)!
            .compactMap { $0 as? URL }
            .filter { !$0.hasDirectoryPath && $0.pathExtension == "swift" }

        for url in fileURLs {
            let encoding = String.Encoding.utf8
            var contents = try String(contentsOf: url, encoding: encoding)

            edit(&contents)

            try contents.write(to: url, atomically: false, encoding: encoding)
        }
    }

    private func installKSSDiff(version: String) async throws {
        let kssDiffSource = try await downloadLibrary(
            .package(url: "https://github.com/klassen-software-solutions/KSSDiff", exact: version)
        )
        let kssDiff = kssDiffSource.appending(path: "KSSDiff-\(version)/Sources/KSSDiff", directoryHint: .isDirectory)
        let kssDiffDestination = currentDir.appendingPathComponent("../SDK/Sources/KSSDiff")

        try? fileManager.removeItem(at: kssDiffDestination)
        try fileManager.copyItem(
            at: kssDiff,
            to: kssDiffDestination
        )

        try editSwiftFiles(at: kssDiffDestination) { swift in
            swift = swift.replacingOccurrences(of: "import KSSFoundation", with: "")
            swift = swift.replacingOccurrences(of: "duration(1.0, .seconds)", with: "1.0")
        }
    }

    private func installCasePaths(version: String) async throws {
        let unzipped = try await downloadLibrary(
            .package(url: "https://github.com/pointfreeco/swift-case-paths", exact: version)
        )
        let source = unzipped.appending(path: "swift-case-paths-\(version)/Sources/CasePaths", directoryHint: .isDirectory)
        let destination = currentDir.appendingPathComponent("../SDK/Sources/CasePaths")

        try? fileManager.removeItem(at: source.appendingPathComponent("Macros.swift"))
        try? fileManager.removeItem(at: source.appendingPathComponent("Documentation.docc"))

        try? fileManager.removeItem(at: destination)
        try fileManager.copyItem(
            at: source,
            to: destination
        )

        try editSwiftFiles(at: destination) { _ in
            // do nothing
        }
    }

    private func installCombineSchedulers(version: String) async throws {
        let unzipped = try await downloadLibrary(
            .package(url: "https://github.com/pointfreeco/combine-schedulers", exact: version)
        )
        let source = unzipped.appending(path: "combine-schedulers-\(version)/Sources/CombineSchedulers", directoryHint: .isDirectory)
        let destination = currentDir.appendingPathComponent("../SDK/Sources/CombineSchedulers")

        try? fileManager.removeItem(at: source.appendingPathComponent("Documentation.docc"))

        try? fileManager.removeItem(at: destination)
        try fileManager.copyItem(
            at: source,
            to: destination
        )

        try editSwiftFiles(at: destination) { _ in
            // do nothing
        }
    }

    private func installConcurrencyExtras(version: String) async throws {
        let unzipped = try await downloadLibrary(
            .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", exact: version)
        )
        let source = unzipped.appending(path: "swift-concurrency-extras-\(version)/Sources/ConcurrencyExtras", directoryHint: .isDirectory)
        let destination = currentDir.appendingPathComponent("../SDK/Sources/ConcurrencyExtras")

        try? fileManager.removeItem(at: source.appendingPathComponent("Documentation.docc"))

        try? fileManager.removeItem(at: destination)
        try fileManager.copyItem(
            at: source,
            to: destination
        )

        try editSwiftFiles(at: destination) { _ in
            // do nothing
        }
    }

    private func installCustomDump(version: String) async throws {
        let unzipped = try await downloadLibrary(
            .package(url: "https://github.com/pointfreeco/swift-custom-dump", exact: version)
        )
        let source = unzipped.appending(path: "swift-custom-dump-\(version)/Sources/CustomDump", directoryHint: .isDirectory)
        let destination = currentDir.appendingPathComponent("../SDK/Sources/CustomDump")

        try? fileManager.removeItem(at: source.appendingPathComponent("Documentation.docc"))

        try? fileManager.removeItem(at: destination)
        try fileManager.copyItem(
            at: source,
            to: destination
        )

        try editSwiftFiles(at: destination) { _ in
            // do nothing
        }
    }

    private func installDependencies(version: String) async throws {
        let unzipped = try await downloadLibrary(
            .package(url: "https://github.com/pointfreeco/swift-dependencies", exact: version)
        )
        let source = unzipped.appending(path: "swift-dependencies-\(version)/Sources/Dependencies", directoryHint: .isDirectory)
        let destination = currentDir.appendingPathComponent("../SDK/Sources/Dependencies")

        try? fileManager.removeItem(at: source.appendingPathComponent("Documentation.docc"))

        try? fileManager.removeItem(at: destination)
        try fileManager.copyItem(
            at: source,
            to: destination
        )

        try editSwiftFiles(at: destination) { _ in
            // do nothing
        }
    }

    private func installIdentifiedCollections(version: String) async throws {
        let unzipped = try await downloadLibrary(
            .package(url: "https://github.com/pointfreeco/swift-identified-collections", exact: version)
        )
        let source = unzipped.appending(
            path: "swift-identified-collections-\(version)/Sources/IdentifiedCollections",
            directoryHint: .isDirectory
        )
        let destination = currentDir.appendingPathComponent("../SDK/Sources/IdentifiedCollections")

        try? fileManager.removeItem(at: source.appendingPathComponent("Documentation.docc"))

        try? fileManager.removeItem(at: destination)
        try fileManager.copyItem(
            at: source,
            to: destination
        )

        try editSwiftFiles(at: destination) { _ in
            // do nothing
        }
    }

    private func installSwiftUINavigation(version: String) async throws {
        let unzipped = try await downloadLibrary(
            .package(url: "https://github.com/pointfreeco/swiftui-navigation", exact: version)
        )
        for sourcePath in ["SwiftUINavigation", "SwiftUINavigationCore"] {
            let source = unzipped.appending(path: "swiftui-navigation-\(version)/Sources/\(sourcePath)", directoryHint: .isDirectory)
            let destination = currentDir.appendingPathComponent("../SDK/Sources/\(sourcePath)")

            try? fileManager.removeItem(at: source.appendingPathComponent("Documentation.docc"))

            try? fileManager.removeItem(at: destination)
            try fileManager.copyItem(
                at: source,
                to: destination
            )

            try editSwiftFiles(at: destination) { _ in
                // do nothing
            }
        }
    }

    private func installXCTestDynamicOverlay(version: String) async throws {
        let unzipped = try await downloadLibrary(
            .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", exact: version)
        )
        let source = unzipped.appending(path: "xctest-dynamic-overlay-\(version)/Sources/XCTestDynamicOverlay", directoryHint: .isDirectory)
        let destination = currentDir.appendingPathComponent("../SDK/Sources/XCTestDynamicOverlay")

        try? fileManager.removeItem(at: source.appendingPathComponent("Documentation.docc"))

        try? fileManager.removeItem(at: destination)
        try fileManager.copyItem(
            at: source,
            to: destination
        )

        try editSwiftFiles(at: destination) { _ in
            // do nothing
        }
    }

    private func installClocks(version: String) async throws {
        let unzipped = try await downloadLibrary(
            .package(url: "https://github.com/pointfreeco/swift-clocks", exact: version)
        )
        let source = unzipped.appending(path: "swift-clocks-\(version)/Sources/Clocks", directoryHint: .isDirectory)
        let destination = currentDir.appendingPathComponent("../SDK/Sources/Clocks")

        try? fileManager.removeItem(at: source.appendingPathComponent("Documentation.docc"))

        try? fileManager.removeItem(at: destination)
        try fileManager.copyItem(
            at: source,
            to: destination
        )

        try editSwiftFiles(at: destination) { _ in
            // do nothing
        }
    }

    private func installComposableArchitecture(version: String) async throws {
        let unzipped = try await downloadLibrary(
            .package(url: "https://github.com/pointfreeco/swift-composable-architecture", exact: version)
        )
        let source = unzipped.appending(
            path: "swift-composable-architecture-\(version)/Sources/ComposableArchitecture",
            directoryHint: .isDirectory
        )
        let destination = currentDir.appendingPathComponent("../SDK/Sources/ComposableArchitecture")

        try? fileManager.removeItem(at: source.appendingPathComponent("Documentation.docc"))
        try? fileManager.removeItem(at: source.appendingPathComponent("Macros.swift"))

        try? fileManager.removeItem(at: destination)
        try fileManager.copyItem(
            at: source,
            to: destination
        )

        try editSwiftFiles(at: destination) { _ in
            // do nothing
        }
    }

    mutating func run() async throws {
        try await installKSSDiff(version: "3.0.1")

        // TCA
        try await installCasePaths(version: "1.3.3")
        try await installCombineSchedulers(version: "1.0.0")
        try await installConcurrencyExtras(version: "1.1.0")
        try await installCustomDump(version: "1.3.0")
        try await installDependencies(version: "1.2.2")
        try await installIdentifiedCollections(version: "1.0.1")
        try await installSwiftUINavigation(version: "1.3.0")
        try await installXCTestDynamicOverlay(version: "1.1.2")
        try await installClocks(version: "1.0.2")
        try await installComposableArchitecture(version: "1.11.1")
    }
}
