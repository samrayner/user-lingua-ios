// StringRecognizer.swift

import Dependencies
import Foundation
import Spyable
import UIKit
import Vision

@Spyable
package protocol StringRecognizerProtocol: ObservableObject {
    var appFacade: UIImage? { get }
    func recognizeStrings() async throws -> [RecognizedString]
}

package final class StringRecognizer: StringRecognizerProtocol {
    enum Error: Swift.Error {
        case invalidImage
        case recognitionRequestFailed(Swift.Error)
    }

    let stringsRepository: StringsRepositoryProtocol
    let windowManager: WindowManagerProtocol
    let appViewModel: any UserLinguaObservableProtocol

    @Published package private(set) var appFacade: UIImage?
    package private(set) var isTakingScreenshot = false

    package init(
        stringsRepository: StringsRepositoryProtocol,
        windowManager: WindowManagerProtocol,
        appViewModel: any UserLinguaObservableProtocol
    ) {
        self.stringsRepository = stringsRepository
        self.windowManager = windowManager
        self.appViewModel = appViewModel
    }

    private func screenshot(window: UIWindow) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(
            window.layer.frame.size,
            false,
            UIScreen.main.scale
        )

        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        window.layer.render(in: context)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return screenshot
    }

    package func recognizeStrings() async throws -> [RecognizedString] {
        guard let appWindow = windowManager.appWindow else { return [] }

        appFacade = screenshot(window: appWindow)

        // refresh views with detectable strings
        isTakingScreenshot = true
        await appViewModel.refresh().value

        // capture screenshot of detectable strings for recognition
        let screenshot = screenshot(window: appWindow)

        // refresh views with original strings
        isTakingScreenshot = false
        appViewModel.refresh()

        let recognizedStrings: [RecognizedString] = if let screenshot {
            try await identifyRecognizedLines(recognizeLines(in: screenshot))
        } else {
            []
        }

        appFacade = nil

        return recognizedStrings
    }

    private func recognizeLines(in image: UIImage) async throws -> [RecognizedLine] {
        guard let cgImage = image.cgImage else {
            throw Error.invalidImage
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage)

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: Error.recognitionRequestFailed(error))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation]
                else {
                    continuation.resume(returning: [])
                    return
                }

                let recognizedText = observations
                    .compactMap { observation in
                        observation.topCandidates(1).first
                    }
                    .map(RecognizedLine.init)

                continuation.resume(returning: recognizedText)
            }

            request.recognitionLevel = .fast
            request.automaticallyDetectsLanguage = false
            request.usesLanguageCorrection = false

            let minimumTextPixelHeight: Double = 6
            request.minimumTextHeight = Float(minimumTextPixelHeight / image.size.height)

            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: Error.recognitionRequestFailed(error))
            }
        }
    }

    func identifyRecognizedLines(_ lines: [RecognizedLine]) -> [RecognizedString] {
        let recordedStrings = stringsRepository.recordedStrings()
        var lines = lines
        var recognizedStrings: [RecognizedString] = []

        // loop recognized lines
        while var line = lines.first {
            var recordedStringFoundForLine = false

            for recordedString in recordedStrings {
                var tokenized = recordedString.detectable
                var recognizedString = RecognizedString(recordedString: recordedString, lines: [])

                defer {
                    if !recognizedString.lines.isEmpty {
                        recognizedStrings.append(recognizedString)
                    }
                }

                // while the line is found at the start of the token
                while let foundPrefix = tokenized.fuzzyFindPrefix(line.string) {
                    recordedStringFoundForLine = true

                    // remove the line from start of the token
                    tokenized = tokenized
                        .dropFirst(foundPrefix.count)
                        .trimmingCharacters(in: .whitespaces)

                    // assign the line to the token it was found in
                    // and remove it from the lines we're looking for
                    recognizedString.lines.append(line)

                    lines.removeFirst()

                    if let nextLine = lines.first {
                        line = nextLine
                    } else {
                        // we've processed all lines, so we're done
                        return recognizedStrings
                    }
                }
            }

            if !recordedStringFoundForLine {
                // no matches found for line, so give up and move onto next
                lines.removeFirst()
            }
        }

        return recognizedStrings
    }
}

extension String {
    private var punctuationCharactersHandledInOcrMistakes: [UnicodeScalar] {
        ["/"]
    }

    private var ocrMistakes: [String: [String]] {
        [
            "l": ["I", "1", "/"],
            "i": ["j"],
            "w": ["vv"],
            "o": ["O", "0"],
            "s": ["S", "5"],
            "v": ["V"],
            "z": ["Z", "2"],
            "u": ["U"],
            "x": ["X"],
            "m": ["nn", "M"]
        ]
    }

    private var ocrMistakesUTF16: [UTF16Char: [[UTF16Char]]] {
        var ocrMistakesUTF16: [UTF16Char: [[UTF16Char]]] = [:]
        for (key, values) in ocrMistakes {
            ocrMistakesUTF16[key.utf16[startIndex]] = values.map { Array($0.utf16) }
        }
        return ocrMistakesUTF16
    }

    private func findNextCharacters(
        prefixUTF16Chars: [UTF16Char],
        prefixIndex: inout Int,
        haystackUTF16Chars: [UTF16Char],
        haystackIndex: inout Int
    ) -> [UTF16Char] {
        let prefixUTF16Char = prefixUTF16Chars[prefixIndex]
        let haystackUTF16Char = haystackUTF16Chars[haystackIndex]

        // return whitespace and punctuation characters as found
        // but don't advance the prefix cursor as they have already
        // been removed from the prefix
        guard let haystackChar = haystackUTF16Char.unicodeScalar,
              !CharacterSet.whitespaces
              .union(.punctuationCharacters)
              .subtracting(.init(punctuationCharactersHandledInOcrMistakes))
              .contains(haystackChar)
        else {
            return [haystackUTF16Char]
        }

        // from now on we want to advance to the next prefix
        // character after matching this one, even if we don't find
        // a match in haystack
        defer {
            prefixIndex += 1
        }

        // if the characters match (case insensitive) move on to next character
        if Character(haystackChar).lowercased() == prefixUTF16Char.unicodeScalar.map(Character.init)?.lowercased() {
            return [haystackUTF16Char]
        }

        // if there are potentially other characters that the prefix character
        // could have been recognized as, loop through them looking for a match
        if let alternatives = ocrMistakesUTF16[prefixUTF16Char] {
            // loop for multi-character alternatives, e.g. nn representing m
            for alternativeChars in alternatives {
                // get the number of characters from the current point in
                // haystack equal to the length of the alternative string
                let rangeEnd = haystackIndex + alternativeChars.count - 1
                guard rangeEnd < haystackUTF16Chars.count else { continue }
                let haystackPrefixChars = Array(haystackUTF16Chars[haystackIndex ... rangeEnd])

                if haystackPrefixChars == alternativeChars {
                    return haystackPrefixChars
                }
            }
        }

        return []
    }

    func fuzzyFindPrefix(_ prefix: String, errorLimit: Double = 0.1) -> String? {
        let haystack = self

        var prefix = prefix

        // swap out all potentially misrecognized substrings with
        // the most likely character they could have been
        for (standard, possibleChars) in ocrMistakes {
            guard let regex = try? Regex("(\(possibleChars.joined(separator: "|")))")
            else { continue }
            prefix = prefix.replacing(regex) { _ in standard }
        }

        // keep only word characters in the string we're finding
        prefix = prefix.replacing(#/[\W_]/#) { _ in "" }

        let prefixUTF16Chars = Array(prefix.utf16)
        let haystackUTF16Chars = Array(haystack.utf16)

        // if the prefix is still longer than the full string, there's no way
        guard prefixUTF16Chars.count <= haystackUTF16Chars.count else { return nil }

        let errorLimit = Int(Double(prefixUTF16Chars.count) * errorLimit)
        var errorCount = 0
        var prefixIndex = 0
        var haystackIndex = 0
        var foundPrefix: [UTF16Char] = []

        while prefixIndex < prefixUTF16Chars.count && haystackIndex < haystackUTF16Chars.count {
            let foundChars = findNextCharacters(
                prefixUTF16Chars: prefixUTF16Chars,
                prefixIndex: &prefixIndex,
                haystackUTF16Chars: haystackUTF16Chars,
                haystackIndex: &haystackIndex
            )

            if foundChars.isEmpty {
                errorCount += 1
                if errorCount > errorLimit {
                    return nil
                }
                haystackIndex += 1
            } else {
                foundPrefix.append(contentsOf: foundChars)
                haystackIndex += foundChars.count
            }
        }

        return String(utf16CodeUnits: foundPrefix, count: foundPrefix.count)
    }
}

extension RecognizedLine {
    private static func boundingBoxOfRecognizedText(_ recognizedText: VNRecognizedText) -> CGRect {
        let stringRange = recognizedText.string.startIndex ..< recognizedText.string.endIndex
        let box = try? recognizedText.boundingBox(for: stringRange)
        let boundingBox = box?.boundingBox ?? .zero
        return VNImageRectForNormalizedRect(boundingBox, Int(UIScreen.main.bounds.width), Int(UIScreen.main.bounds.height))
    }

    init(_ vnRecognizedText: VNRecognizedText) {
        self = .init(
            string: vnRecognizedText.string,
            boundingBox: Self.boundingBoxOfRecognizedText(vnRecognizedText)
        )
    }
}

package enum StringRecognizerDependency: DependencyKey {
    package static let liveValue: any StringRecognizerProtocol = {
        @Dependency(StringsRepositoryDependency.self) var stringsRepository
        @Dependency(WindowManagerDependency.self) var windowManager
        @Dependency(UserLinguaObservableDependency.self) var appViewModel
        return StringRecognizer(
            stringsRepository: stringsRepository,
            windowManager: windowManager,
            appViewModel: appViewModel
        )
    }()

    package static let previewValue: any StringRecognizerProtocol = StringRecognizerProtocolSpy()
    package static let testValue: any StringRecognizerProtocol = StringRecognizerProtocolSpy()
}
