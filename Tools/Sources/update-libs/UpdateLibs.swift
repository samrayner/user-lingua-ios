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
        let kssDiffDestination = currentDir.appendingPathComponent("../SDK/Sources/Lib_KSSDiff")

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
        let source = try await downloadLibrary(
            .package(url: "https://github.com/pointfreeco/swift-case-paths", exact: version)
        )
        let casePaths = source.appending(path: "swift-case-paths-\(version)/Sources/CasePaths", directoryHint: .isDirectory)
        let destination = currentDir.appendingPathComponent("../SDK/Sources/Lib_CasePaths")

        try? fileManager.removeItem(at: destination)
        try fileManager.copyItem(
            at: casePaths,
            to: destination
        )

        try editSwiftFiles(at: destination) { swift in
            swift = swift.replacingOccurrences(of: " CasePaths.", with: " Lib_CasePaths.")
        }
    }

    private func installMobius(version: String) async throws {
        let source = try await downloadLibrary(
            .package(url: "https://github.com/spotify/Mobius.swift", exact: version)
        )
        .appending(path: "Mobius.swift-\(version)", directoryHint: .isDirectory)

        let mobiusCore = source.appending(path: "MobiusCore", directoryHint: .isDirectory)
        let mobiusExtras = source.appending(path: "MobiusExtras", directoryHint: .isDirectory)

        let destination = currentDir.appendingPathComponent("../SDK/Sources/Lib_Mobius")

        try? fileManager.removeItem(at: destination)
        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)

        for source in [mobiusCore, mobiusExtras] {
            try fileManager.copyItem(
                at: source.appending(
                    path: "Source",
                    directoryHint: .isDirectory
                ),
                to: destination.appending(path: source.lastPathComponent)
            )
        }

        try editSwiftFiles(at: destination) { swift in
            swift = swift.replacingOccurrences(of: "import MobiusCore", with: "")
            swift = swift.replacingOccurrences(of: "import CasePaths", with: "import Lib_CasePaths")
            swift = swift.replacingOccurrences(of: " CasePaths.", with: " Lib_CasePaths.")
            swift = swift.replacingOccurrences(of: " MobiusCore.", with: " Lib_Mobius.")
        }
    }

    mutating func run() async throws {
        try await installKSSDiff(version: "3.0.1")
        try await installCasePaths(version: "0.10.1")
        try await installMobius(version: "0.5.2")
    }
}
