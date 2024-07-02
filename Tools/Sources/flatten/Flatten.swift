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

            let destination = currentDir.deletingLastPathComponent()
                .appendingPathComponent("FlatSDK/Sources/UserLingua/Modules/\(moduleName)")
            try? fileManager.removeItem(at: destination)

            let swiftFileURLs = fileManager
                .enumerator(at: modulePath, includingPropertiesForKeys: nil)!
                .compactMap { $0 as? URL }
                .filter { !$0.hasDirectoryPath && $0.pathExtension == "swift" }

            for url in swiftFileURLs {
                let encoding = String.Encoding.utf8
                var contents = try String(contentsOf: url, encoding: encoding)

                let importedModules = [
                    "CasePaths",
                    "CombineSchedulers",
                    "CombineFeedback",
                    "Core",
                    "CustomDump",
                    "Dependencies",
                    "Diff",
                    "InspectionFeature",
                    "KSSDiff",
                    "RecognitionFeature",
                    "RootFeature",
                    "SelectionFeature",
                    "Strings",
                    "SystemAPIAliases",
                    "Theme",
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
                if url.lastPathComponent != "PrimaryButtonStyle.swift" {
                    contents = contents
                        .replacingOccurrences(
                            of: "(@_spi\\(.*\\) )?public\\s{1,}",
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
                        of: "CustomDump.customDump(",
                        with: "customDump("
                    )
                    .replacingOccurrences(
                        of: "Core.Configuration",
                        with: "Configuration"
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
                let filePath = destination.appendingPathComponent("\(moduleName)_\(url.lastPathComponent)")
                try contents.write(to: filePath, atomically: false, encoding: encoding)

                try? fileManager.removeItem(at: destination.appendingPathComponent("CasePaths_TypeName.swift"))
            }
        }
    }
}
