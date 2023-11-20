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
            let tokenizedString = TokenizedString(string)
            return tokenizedString.detectable
        case .previewingSuggestion:
            let suggestion = UserLingua.shared.db.suggestion(for: string)
            return suggestion.map { $0.newValue } ?? string
        }
    }
    
    /// Goals of tokenization:
    /// - Maximise string uniqueness
    /// - Maintain exact wrapping of the original string (i.e. exact "word" widths)
    /// - Do not decrease OCR accuracy (increase it if possible)
    func tokenized() -> String {
        //strip diacritics to improve OCR
        let utf16 = self.folding(options: .diacriticInsensitive, locale: .current).utf16
        var codeUnits = Array(utf16)
        
        func codeUnitIsSwappable(_ codeUnit: UTF16View.Element) -> Bool {
            guard let currentChar = Unicode.Scalar(UInt32(codeUnit)) 
            else { return false }
            
            return !CharacterSet.whitespaces
                .union(.punctuationCharacters)
                .contains(currentChar)
        }
        
        var currentIndex = 0
        var swapRangeStartIndex = 0
        while currentIndex < codeUnits.count {
            defer { currentIndex += 1 }
            
            //maintain the positions of all whitespace and punctuation
            //to preserve exact wrap points of original string
            guard codeUnitIsSwappable(codeUnits[currentIndex]) else {
                swapRangeStartIndex = currentIndex + 1
                continue
            }
            
            if currentIndex > swapRangeStartIndex + 1,
               let previousIndex = (swapRangeStartIndex..<currentIndex).randomElement() {
                codeUnits.swapAt(currentIndex, swapRangeStartIndex) //TODO: previousIndex
            }
        }
        
        return String(utf16CodeUnits: codeUnits, count: codeUnits.count)
    }
}

extension String {
    func fuzzed() -> Self {
        let nonWordRegex = try! Regex("\\W")
        var fuzzed = self.replacing(nonWordRegex, with: "")
        
        let commonlyConfusedAlphanumerics = [
            "l": ["I", "1"],
            "j": ["i"],
            "w": ["vv"],
            "o": ["O", "0"],
            "s": ["S", "5"],
            "v": ["V"],
            "z": ["Z", "2"],
            "u": ["U"],
            "x": ["X"],
            "m": ["nn", "M"]
        ]
        
        for (replacement, confused) in commonlyConfusedAlphanumerics {
            let regex = try! Regex("(\(confused.joined(separator: "|")))")
            fuzzed = fuzzed.replacing(regex) { _ in replacement }
        }
        
        return fuzzed
    }
}
