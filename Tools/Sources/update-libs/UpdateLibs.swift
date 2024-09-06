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

    private func editSwiftFiles(at url: URL, edit: (URL, inout String) -> Void) throws {
        let fileURLs = fileManager
            .enumerator(at: url, includingPropertiesForKeys: nil)!
            .compactMap { $0 as? URL }
            .filter { !$0.hasDirectoryPath && $0.pathExtension == "swift" }

        for url in fileURLs {
            let encoding = String.Encoding.utf8
            var contents = try String(contentsOf: url, encoding: encoding)

            edit(url, &contents)

            try contents.write(to: url, atomically: false, encoding: encoding)
        }
    }

    private func installKSSDiff(version: String) async throws {
        let unzipped = try await downloadLibrary(
            .package(url: "https://github.com/klassen-software-solutions/KSSDiff", exact: version)
        )
        let source = unzipped.appending(path: "KSSDiff-\(version)/Sources/KSSDiff", directoryHint: .isDirectory)
        let destination = currentDir.appendingPathComponent("../SDK/Sources/KSSDiff")

        try? fileManager.removeItem(at: destination)
        try fileManager.copyItem(
            at: source,
            to: destination
        )

        try editSwiftFiles(at: destination) { _, swift in
            swift = swift.replacingOccurrences(of: "import KSSFoundation", with: "")
            swift = swift.replacingOccurrences(of: "duration(1.0, .seconds)", with: "1.0")
        }
    }

    private func installGRDB(version: String) async throws {
        let unzipped = try await downloadLibrary(
            .package(url: "https://github.com/groue/GRDB.swift", exact: "v\(version)")
        )
        let target = "GRDB"
        let source = unzipped.appending(path: "GRDB.swift-\(version)/\(target)", directoryHint: .isDirectory)
        let destination = currentDir.appendingPathComponent("../SDK/Sources/\(target)")

        try? fileManager.removeItem(at: source.appendingPathComponent("Documentation.docc"))

        try? fileManager.removeItem(at: destination)
        try fileManager.copyItem(
            at: source,
            to: destination
        )

        try editSwiftFiles(at: destination) { fileURL, swift in
            if fileURL.lastPathComponent == "Export.swift" {
                swift = """
                    @_exported import SQLite3
                    internal func _enableDoubleQuotedStringLiterals(_: SQLiteConnection?) {}
                    internal func _disableDoubleQuotedStringLiterals(_: SQLiteConnection?) {}
                    internal func _registerErrorLogCallback(_: ((Void, CInt, CChar?) -> Void)?) {}
                """
            }
        }
    }

    private func installAnyCodable(version: String) async throws {
        let unzipped = try await downloadLibrary(
            .package(url: "https://github.com/Flight-School/AnyCodable", exact: version)
        )
        let target = "AnyCodable"
        let source = unzipped.appending(path: "\(target)-\(version)/Sources/\(target)", directoryHint: .isDirectory)
        let destination = currentDir.appendingPathComponent("../SDK/Sources/\(target)")

        try? fileManager.removeItem(at: destination)
        try fileManager.copyItem(
            at: source,
            to: destination
        )

        try editSwiftFiles(at: destination) { _, _ in
        }
    }

    private func installPointFreeLibrary(package: String, target: String, version: String) async throws {
        let unzipped = try await downloadLibrary(
            .package(url: "https://github.com/pointfreeco/\(package)", exact: version)
        )
        let source = unzipped.appending(path: "\(package)-\(version)/Sources/\(target)", directoryHint: .isDirectory)
        let destination = currentDir.appendingPathComponent("../SDK/Sources/\(target)")

        try? fileManager.removeItem(at: source.appendingPathComponent("Documentation.docc"))

        try? fileManager.removeItem(at: destination)
        try fileManager.copyItem(
            at: source,
            to: destination
        )

        try editSwiftFiles(at: destination) { _, _ in
            // do nothing
        }
    }

    private func installCasePaths(version: String) async throws {
        try await installPointFreeLibrary(
            package: "swift-case-paths",
            target: "CasePaths",
            version: version
        )
    }

    private func installCombineSchedulers(version: String) async throws {
        try await installPointFreeLibrary(
            package: "combine-schedulers",
            target: "CombineSchedulers",
            version: version
        )
    }

    private func installCustomDump(version: String) async throws {
        try await installPointFreeLibrary(
            package: "swift-custom-dump",
            target: "CustomDump",
            version: version
        )
    }

    private func installXCTestDynamicOverlay(version: String) async throws {
        try await installPointFreeLibrary(
            package: "swift-issue-reporting",
            target: "XCTestDynamicOverlay",
            version: version
        )
    }

    mutating func run() async throws {
        try await installKSSDiff(version: "3.0.1")
        try await installGRDB(version: "6.29.0")
        try await installAnyCodable(version: "0.6.7")

        // TCA
        try await installCasePaths(version: "1.0.0")
        try await installCombineSchedulers(version: "0.10.0")
        try await installCustomDump(version: "1.3.0")
        try await installXCTestDynamicOverlay(version: "1.1.2")
    }
}
