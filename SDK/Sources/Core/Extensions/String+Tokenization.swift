// String+Tokenization.swift

import Foundation

extension String {
    /// Goals of tokenization:
    /// - Maximise string uniqueness
    /// - Maintain exact wrapping of the original string (i.e. exact "word" widths)
    /// - Do not decrease OCR accuracy (increase it if possible)
    public func tokenized() -> String {
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
