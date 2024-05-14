// UpdateLibs.swift

import ArgumentParser
import Foundation
import Zip

private let libraries: Set<Library> = [
    .package(url: "https://github.com/klassen-software-solutions/KSSDiff", exact: "3.0.1"),
    .package(url: "https://github.com/pointfreeco/combine-schedulers", exact: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", exact: "1.10.4"),
    .package(url: "https://github.com/pointfreeco/swift-case-paths", exact: "1.3.0"),
    .package(url: "https://github.com/pointfreeco/swift-clocks", exact: "1.0.2"),
    .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", exact: "1.1.0"),
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", exact: "1.3.0"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", exact: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-identified-collections", exact: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swiftui-navigation", exact: "1.1.0"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", exact: "1.1.0")
]

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

    private func downloadLibrary(_ library: Library) async throws -> URL {
        let (data, _) = try await URLSession.shared.data(from: library.zipURL)

        let tempDir = NSURL.fileURL(withPath: NSTemporaryDirectory(), isDirectory: true)

        let zipFile = tempDir.appendingPathComponent("\(library.repoURL.lastPathComponent).zip")

        try data.write(to: zipFile)

        let unzippedDir = tempDir.appendingPathComponent("\(library.repoURL.lastPathComponent)-\(library.version)")

        try Zip.unzipFile(
            zipFile,
            destination: unzippedDir,
            overwrite: true,
            password: nil
        )

        return unzippedDir
    }

    private func targetDirs(of unzippedDir: URL) throws -> [URL] {
        let enumerator = fileManager.enumerator(at: unzippedDir, includingPropertiesForKeys: nil)!

        var targetDirs: [URL] = []

        for case let url as URL in enumerator where enumerator.level < 4 {
            if url.hasDirectoryPath,
               url.deletingLastPathComponent().lastPathComponent == "Sources",
               !url.lastPathComponent.hasSuffix("benchmark"),
               !url.lastPathComponent.hasSuffix("Macros") {
                targetDirs.append(url)
            }
        }

        return targetDirs
    }

    mutating func run() async throws {
        let fileManager = FileManager.default

        var unzippedDirs: [URL] = []
        for library in libraries {
            try await unzippedDirs.append(downloadLibrary(library))
        }

        let sourceDirs = try unzippedDirs.flatMap(targetDirs)
        let currentDir = URL(fileURLWithPath: fileManager.currentDirectoryPath)

        for source in sourceDirs {
            try? fileManager.removeItem(at: source.appendingPathComponent("Documentation.docc"))

            let fileURLs = fileManager.enumerator(at: source, includingPropertiesForKeys: nil)!
                .compactMap { $0 as? URL }
                .filter { !$0.hasDirectoryPath && $0.pathExtension == "swift" }

            for url in fileURLs {
                let encoding = String.Encoding.utf8
                var contents = try String(contentsOf: url, encoding: encoding)

                for source in sourceDirs {
                    let oldTargetName = source.lastPathComponent
                    let newTargetName = "Lib_\(source.lastPathComponent)"

                    contents = contents.replacingOccurrences(
                        of: "import \(oldTargetName)",
                        with: "import \(newTargetName)"
                    )
                }

                try contents.write(to: url, atomically: false, encoding: encoding)
            }

            let destination = currentDir.appendingPathComponent("../SDK/Sources/Lib_\(source.lastPathComponent)")
            try? fileManager.removeItem(at: destination)
            try fileManager.copyItem(
                at: source,
                to: destination
            )
        }
    }
}
