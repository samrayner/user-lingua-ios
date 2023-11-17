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
            return tokenizedString.token
        case .previewingSuggestion:
            let suggestion = UserLingua.shared.db.suggestion(for: string)
            return suggestion.map { $0.newValue } ?? string
        }
    }
    
    func tokenized() -> String {
        let utf16 = self.utf16
        var codeUnits = Array(utf16)
        
        func charIsSwappable(_ codeUnit: UTF16.CodeUnit) -> Bool {
            guard let character = Unicode.Scalar(UInt32(codeUnit)) else { return false }
            
            return !CharacterSet.punctuationCharacters
                .union(.whitespacesAndNewlines)
                .contains(character)
        }
        
        var i = 0
        while i < codeUnits.count - 1 {
            defer { i += 1 }
            
            guard charIsSwappable(codeUnits[i]),
                  charIsSwappable(codeUnits[i + 1])
            else { continue }
            
            //TODO: re-enable randomness when screenshotting isn't using an asset
            //if Bool.random() {
                codeUnits.swapAt(i, i + 1)
            //}
        }
        
        return String(utf16CodeUnits: codeUnits, count: codeUnits.count)
    }
}
