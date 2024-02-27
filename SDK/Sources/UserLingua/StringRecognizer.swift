// StringRecognizer.swift

import Foundation
import Spyable
import UIKit
import Vision

@Spyable
protocol StringRecognizerProtocol {
    typealias RecognizedString = (recordedString: RecordedString, textBlocks: [RecognizedText])

    func recognizeStrings(in image: UIImage) async throws -> [RecognizedString]
}

struct StringRecognizer: StringRecognizerProtocol {
    enum Error: Swift.Error {
        case invalidImage
        case recognitionRequestFailed(Swift.Error)
    }

    let stringsRepository: StringsRepositoryProtocol

    init(stringsRepository: StringsRepositoryProtocol) {
        self.stringsRepository = stringsRepository
    }

    func recognizeStrings(in image: UIImage) async throws -> [RecognizedString] {
        try await identifyRecognizedText(recognizeText(in: image))
    }

    private func recognizeText(in image: UIImage) async throws -> [RecognizedText] {
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
                    .map(RecognizedText.init)

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

    func identifyRecognizedText(_ recognizedText: [RecognizedText]) -> [RecognizedString] {
        let recordedStrings = stringsRepository.recordedStrings()
        var textBlocks = recognizedText
        var recognizedStrings: [RecognizedString] = []

        // loop recognized text blocks
        while var textBlock = textBlocks.first {
            var recordedStringFoundForTextBlock = false

            for recordedString in recordedStrings {
                var tokenized = recordedString.detectable
                var recognizedString: RecognizedString = (recordedString, [])

                defer {
                    if !recognizedString.textBlocks.isEmpty {
                        recognizedStrings.append(recognizedString)
                    }
                }

                // while the text block is found at the start of the token
                while let foundPrefix = tokenized.fuzzyFindPrefix(textBlock.string) {
                    recordedStringFoundForTextBlock = true

                    // remove the text block from start of the token
                    tokenized = tokenized
                        .dropFirst(foundPrefix.count)
                        .trimmingCharacters(in: .whitespaces)

                    // assign the text block to the token it was found in
                    // and remove it from the text blocks we're looking for
                    recognizedString.textBlocks.append(textBlock)

                    textBlocks.removeFirst()

                    if let nextTextBlock = textBlocks.first {
                        textBlock = nextTextBlock
                    } else {
                        // we've processed all text blocks, so we're done
                        return recognizedStrings
                    }
                }
            }

            if !recordedStringFoundForTextBlock {
                // no matches found for text block, so give up and move onto next
                textBlocks.removeFirst()
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

    /// Goals of tokenization:
    /// - Maximise string uniqueness
    /// - Maintain exact wrapping of the original string (i.e. exact "word" widths)
    /// - Do not decrease OCR accuracy (increase it if possible)
    func tokenized() -> String {
        // strip diacritics to improve OCR
        let utf16 = folding(options: .diacriticInsensitive, locale: .current).utf16
        var utf16Chars = Array(utf16)

        func characterIsSwappable(_ utf16Char: UTF16Char) -> Bool {
            guard let currentChar = utf16Char.unicodeScalar
            else { return false }

            return !CharacterSet.whitespaces
                .union(.punctuationCharacters)
                .contains(currentChar)
        }

        var currentIndex = 0
        var swapRangeStartIndex = 0
        while currentIndex < utf16Chars.count {
            defer { currentIndex += 1 }

            // maintain the positions of all whitespace and punctuation
            // to preserve exact wrap points of original string
            guard characterIsSwappable(utf16Chars[currentIndex]) else {
                swapRangeStartIndex = currentIndex + 1
                continue
            }

            if currentIndex > swapRangeStartIndex + 1,
               let previousIndex = (swapRangeStartIndex ..< currentIndex).randomElement() {
                utf16Chars.swapAt(currentIndex, previousIndex)
            }
        }

        return String(utf16CodeUnits: utf16Chars, count: utf16Chars.count)
    }
}

extension UTF16Char {
    var unicodeScalar: Unicode.Scalar? {
        Unicode.Scalar(UInt32(self))
    }
}

extension RecognizedText {
    private static func rectForTextBlock(_ textBlock: VNRecognizedText) -> CGRect {
        let stringRange = textBlock.string.startIndex ..< textBlock.string.endIndex
        let box = try? textBlock.boundingBox(for: stringRange)
        let boundingBox = box?.boundingBox ?? .zero
        return VNImageRectForNormalizedRect(boundingBox, Int(UIScreen.main.bounds.width), Int(UIScreen.main.bounds.height))
    }

    init(_ vnRecognizedText: VNRecognizedText) {
        self = .init(
            string: vnRecognizedText.string,
            boundingBox: Self.rectForTextBlock(vnRecognizedText)
        )
    }
}
