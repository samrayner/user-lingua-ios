import Foundation

extension StringProtocol {
    public func userLingua() -> String {
        let string = String(self)
        
        switch UserLingua.shared.state {
        case .disabled, .highlightingStrings:
            return string
        case .recordingStrings:
            UserLingua.shared.db.record(string: string)
            return string
        case .detectingStrings:
            guard let recordedString = UserLingua.shared.db.recordedString(for: string) else {
                return string
            }
            return recordedString.detectable
        case .previewingSuggestion:
            guard let suggestion = UserLingua.shared.db.suggestion(for: string) else {
                return string
            }
            return suggestion.newValue
        }
    }
    
    /// Goals of tokenization:
    /// - Maximise string uniqueness
    /// - Maintain exact wrapping of the original string (i.e. exact "word" widths)
    /// - Do not decrease OCR accuracy (increase it if possible)
    func tokenized() -> String {
        //strip diacritics to improve OCR
        let utf16 = self.folding(options: .diacriticInsensitive, locale: .current).utf16
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
            
            //maintain the positions of all whitespace and punctuation
            //to preserve exact wrap points of original string
            guard characterIsSwappable(utf16Chars[currentIndex]) else {
                swapRangeStartIndex = currentIndex + 1
                continue
            }
            
            if currentIndex > swapRangeStartIndex + 1,
               let previousIndex = (swapRangeStartIndex..<currentIndex).randomElement() {
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
