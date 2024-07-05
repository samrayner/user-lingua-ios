// Flatten.swift

import ArgumentParser
import Foundation

@main
struct UpdateLibs: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Flatten modules into a single one.")

    var fileManager: FileManager { FileManager.default }
    var currentDir: URL { URL(fileURLWithPath: fileManager.currentDirectoryPath) }

    mutating func run() async throws {
        let sourcesPath = currentDir.appendingPathComponent("../SDK/Sources")

        let dirURLs = try fileManager
            .contentsOfDirectory(at: sourcesPath, includingPropertiesForKeys: nil)

        let macrosDirURLs = dirURLs
            .filter { $0.hasDirectoryPath && $0.lastPathComponent.hasSuffix("Macros") }

        let sourceDirURLs = dirURLs
            .filter { $0.hasDirectoryPath && !$0.lastPathComponent.hasSuffix("Macros") }

        for url in macrosDirURLs {
            let destination = currentDir.deletingLastPathComponent().appendingPathComponent("FlatSDK/Sources/\(url.lastPathComponent)")

            try? fileManager.removeItem(at: destination)
            try fileManager.copyItem(
                at: url,
                to: destination
            )
        }

        for modulePath in sourceDirURLs {
            let moduleName = modulePath.lastPathComponent

            if moduleName == "UserLingua" {
                let destination = currentDir.deletingLastPathComponent()
                    .appendingPathComponent("FlatSDK/Sources/\(moduleName)")
                try? fileManager.removeItem(at: destination)
                try fileManager.copyItem(
                    at: modulePath,
                    to: destination
                )
                continue
            }

            let destination = currentDir.deletingLastPathComponent()
                .appendingPathComponent("FlatSDK/Sources/UserLinguaCore/Modules/\(moduleName)")
            try? fileManager.removeItem(at: destination)

            let swiftFileURLs = fileManager
                .enumerator(at: modulePath, includingPropertiesForKeys: nil)!
                .compactMap { $0 as? URL }
                .filter { !$0.hasDirectoryPath && $0.pathExtension == "swift" }

            for url in swiftFileURLs {
                let filename = url.lastPathComponent
                let encoding = String.Encoding.utf8
                var contents = try String(contentsOf: url, encoding: encoding)

                let importedModules = [
                    "CasePaths",
                    "CombineSchedulers",
                    "CombineFeedback",
                    "CustomDump",
                    "Dependencies",
                    "Diff",
                    "InspectionFeature",
                    "KSSDiff",
                    "Models",
                    "RecognitionFeature",
                    "RootFeature",
                    "SelectionFeature",
                    "Strings",
                    "Theme",
                    "Utilities",
                    "XCTestDynamicOverlay"
                ]

                // imports that now live in same module
                for importedModule in importedModules {
                    contents = contents
                        .replacingOccurrences(
                            of: " *(@[^ ]* )?import \(importedModule)[^\\w]",
                            with: "",
                            options: .regularExpression
                        )
                }

                // public access level that should be internal now
                if moduleName != "UserLinguaCore" && !["UserLinguaObservable.swift", "UserLinguaConfiguration.swift"].contains(filename) {
                    contents = contents
                        .replacingOccurrences(
                            of: "(@_spi\\(.*\\) )?(public|open) {1,}",
                            with: "",
                            options: .regularExpression
                        )
                }

                // public protocol conformances
                contents = contents
                    .replacingOccurrences(
                        of: "static func == ",
                        with: "public static func == "
                    )
                    .replacingOccurrences(
                        of: "func hash(into hasher:",
                        with: "public func hash(into hasher:"
                    )
                    .replacingOccurrences(
                        of: "func cancel()",
                        with: "public func cancel()"
                    )

                // namespaced module-level declarations
                contents = contents
                    .replacingOccurrences(
                        of: "(CustomDump|CasePaths)\\.",
                        with: "UserLinguaCore.",
                        options: .regularExpression
                    )
                    .replacingOccurrences(
                        of: "public typealias UserLinguaConfiguration = Models.UserLinguaConfiguration",
                        with: ""
                    )

                // duplicate implementations
                if moduleName == "CasePaths" {
                    // duplicated in CustomDump
                    contents = contents
                        .replacingOccurrences(
                            of: "_OptionalProtocol",
                            with: "\(moduleName)_OptionalProtocol"
                        )
                }

                try? fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
                let filePath = destination.appendingPathComponent("\(moduleName)_\(filename)")
                try contents.write(to: filePath, atomically: false, encoding: encoding)

                // duplicate implementations
                try? fileManager.removeItem(at: destination.appendingPathComponent("CasePaths_TypeName.swift"))
            }
        }
    }
}
