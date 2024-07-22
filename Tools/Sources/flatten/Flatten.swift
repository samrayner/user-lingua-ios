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
            .filter(\.hasDirectoryPath)

        let resourcesDestination = currentDir.deletingLastPathComponent().appendingPathComponent("FlatSDK/Sources/UserLinguaCore/Resources")

        let sourceModules = ["UserLingua", "UserLinguaAuto", "UserLinguaMacros", "UserLinguaExternalMacros"]
        let userLinguaModules = sourceModules + ["UserLinguaCore"]
        let importedModules = Set(dirURLs.map(\.lastPathComponent)).subtracting(userLinguaModules)

        for modulePath in dirURLs {
            let moduleName = modulePath.lastPathComponent

            if sourceModules.contains(moduleName) {
                let destination = currentDir.deletingLastPathComponent()
                    .appendingPathComponent("FlatSDK/Sources/\(moduleName)")
                try? fileManager.removeItem(at: destination)
                try fileManager.copyItem(
                    at: modulePath,
                    to: destination
                )
                continue
            }

            let resourcesPath = modulePath.appendingPathComponent("Resources")
            if fileManager.fileExists(atPath: resourcesPath.path) {
                let resourceURLs = try fileManager
                    .contentsOfDirectory(at: resourcesPath, includingPropertiesForKeys: nil)
                    .filter { !$0.lastPathComponent.starts(with: ".") }

                for url in resourceURLs {
                    let destination = resourcesDestination.appendingPathComponent(url.lastPathComponent)

                    try? fileManager.removeItem(at: destination)
                    try fileManager.copyItem(
                        at: url,
                        to: destination
                    )
                }
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
                            with: "internal ",
                            options: .regularExpression
                        )
                }

                // public protocol conformances
                contents = contents
                    .replacingOccurrences(
                        of: "internal static func == ",
                        with: "public static func == "
                    )
                    .replacingOccurrences(
                        of: "internal func hash(into hasher:",
                        with: "public func hash(into hasher:"
                    )
                    .replacingOccurrences(
                        of: "internal func cancel()",
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

                // avoid collision with SwiftUI
                if moduleName == "SQLite" {
                    contents = contents
                        .replacingOccurrences(of: "View", with: "ViewSchema")
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
