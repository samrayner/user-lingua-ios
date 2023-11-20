import UIKit
import SwiftUI
import OrderedCollections
import Vision

struct Localization: Hashable {
    var key: String
    var tableName: String?
    var comment: String?
}

struct LocalizedString: Hashable {
    var value: String
    var localization: Localization
}

struct TokenizedString: Hashable {
    let original: String
    let detectable: String
    
    init(_ value: String) {
        self.original = value
        
        let tokenized = value.tokenized()
        self.detectable = tokenized
    }
}

struct Suggestion {
    var oldValue: String
    var newValue: String
    var locale: Locale
    var localization: Localization?
    var createdAt: Date = .now
    var modifiedAt: Date = .now
    var isSubmitted = false
    var screenshot: UIImage?
}

final public class UserLingua {
    enum State {
        case disabled
        case recordingStrings
        case detectingStrings
        case highlightingStrings
        case previewingSuggestion
    }
    
    public struct Configuration {
        public var automaticallyOptInLocalizedTextViews: Bool
        
        public init(
            automaticallyOptInLocalizedTextViews: Bool = true
        ) {
            self.automaticallyOptInLocalizedTextViews = automaticallyOptInLocalizedTextViews
        }
    }
    
    public static let shared = UserLingua()
    
    let db = Database()
    public var config = Configuration()
    var state: State = .disabled
    
    init() {}
    
    public func enable(config: Configuration = .init()) {
        self.config = config
        state = .recordingStrings
    }
    
    func processLocalizedText(_ originalText: Text) -> Text {      
        guard UserLingua.shared.state != .disabled,
              let storage = Reflection.value("storage", on: originalText),
              let textStorage = Reflection.value("anyTextStorage", on: storage)
        else { return originalText }
        
        let textStorageType = "\(type(of: textStorage))"
        
        switch textStorageType {
        case "LocalizedTextStorage":
            guard let localizedString = localizedString(from: textStorage)
            else { return originalText }
            
            switch UserLingua.shared.state {
            case .disabled, .highlightingStrings:
                return originalText
            case .recordingStrings:
                UserLingua.shared.db.record(localizedString: localizedString)
                return originalText
            case .detectingStrings:
                let tokenizedString = TokenizedString(localizedString.value)
                return .init(verbatim: tokenizedString.detectable)
            case .previewingSuggestion:
                let suggestion = UserLingua.shared.db.suggestion(for: localizedString)
                return suggestion.map { .init(verbatim: $0.newValue) } ?? originalText
            }
        case "AttributedStringTextStorage":
            //we probably want to support this in future
            return originalText
        default:
            //there are more types we will probably never support
            return originalText
        }
    }
    
    private func localizedString(from localizedTextStorage: Any) -> LocalizedString? {
        guard let localizedStringKey = Reflection.value("key", on: localizedTextStorage)
        else { return nil }
        
        guard let key = Reflection.value("key", on: localizedStringKey) as? String
        else { return nil }
        
        let bundle = Reflection.value("bundle", on: localizedTextStorage) as? Bundle
        let tableName = Reflection.value("table", on: localizedTextStorage) as? String
        let comment = Reflection.value("comment", on: localizedTextStorage) as? String
        
        let value = bundle?.localizedString(forKey: key, value: nil, table: tableName)
        
        return LocalizedString(
            value: value ?? key,
            localization: .init(
                key: key,
                tableName: tableName,
                comment: comment
            )
        )
    }
    
    private func snapshot() -> UIImage {
        UIImage(resource: .screenshot)
    }
    
    public func findAllText() {
        guard let cgImage = snapshot().cgImage else { return }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
        request.recognitionLevel = .fast
        request.automaticallyDetectsLanguage = false
        request.usesLanguageCorrection = false
        
        do {
            try requestHandler.perform([request])
        } catch {
            print("Unable to perform the requests: \(error).")
        }
    }
    
    private func recognizeTextHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNRecognizedTextObservation]
        else { return }
        
        let recognizedText = observations
            .compactMap { observation in
                observation.topCandidates(1).first
            }
        
        let matches = matchRecognizedTextToKnownStrings(recognizedText)
        
        for (recordedString, textBlocks) in matches {
            print(recordedString.original, textBlocks.map(\.string))
        }
    }
    
    private func matchRecognizedTextToKnownStrings(
        _ recognizedText: [VNRecognizedText]
    ) -> [TokenizedString: [VNRecognizedText]] {
        var textBlocks = recognizedText
        var matches: [TokenizedString: [VNRecognizedText]] = [:]
        
        //loop recognized text blocks
        while var textBlock = textBlocks.first {
            var recordedStringFoundForTextBlock = false
            
            for recordedString in db.stringRecord where matches[recordedString] == nil {
                var tokenized = recordedString.detectable
                
                //while the text block is found at the start of the token
                while tokenized.fuzzyFindPrefix(textBlock.string) != nil {
                    recordedStringFoundForTextBlock = true
                    
                    print("\n\nremoving <<<\(textBlock.string)>>> from: [[[\(tokenized)]]]")
                    
                    //remove the text block from start of the token
                    tokenized = tokenized
                        .dropFirst(textBlock.string.count)
                        .trimmingCharacters(in: .whitespaces)
                    
                    print("=== \(tokenized)")
                    
                    //assign the text block to the token it was found in
                    //and remove it from the text blocks we're looking for
                    matches[recordedString, default: []].append(textBlock)

                    textBlocks.removeFirst()
                    
                    if let nextTextBlock = textBlocks.first {
                        textBlock = nextTextBlock
                    } else {
                        //we've processed all text blocks, so we're done
                        return matches
                    }
                }
            }
            
            if !recordedStringFoundForTextBlock {
                //no matches found for text block, so give up and move onto next
                textBlocks.removeFirst()
            }
        }
        
        return matches
    }
}

final class Database {
    var stringRecord: OrderedSet<TokenizedString> = [] {
        didSet { stringRecord.trimFront() }
    }
    
    var localizations: [String: Set<LocalizedString>] = [:]
    var suggestions: [String: [Suggestion]] = [
        "Text value %@": [
            .init(
                oldValue: "Text value %@",
                newValue: "Sam2",
                locale: .current
            )
        ]
    ]
    
    func record(string: String) {
        let tokenized = TokenizedString(string)
        stringRecord.remove(tokenized)
        stringRecord.append(tokenized)
    }
    
    func record(localizedString: LocalizedString) {
        record(string: localizedString.value)
        localizations[localizedString.value, default: []].insert(localizedString)
    }
    
    func suggestions(for oldValue: String) -> [Suggestion] {
        suggestions[oldValue, default: []].filter {
            $0.locale == .current
        }
    }
    
    func suggestion(for localizedString: LocalizedString) -> Suggestion? {
        let matchingValues = suggestions(for: localizedString.value)
        return matchingValues.first {
            $0.localization == localizedString.localization
        } ?? matchingValues.first
    }
    
    func suggestion(for oldValue: String) -> Suggestion? {
        suggestions(for: oldValue).first
    }
}

private enum Reflection {
    static func value(
        _ label: String,
        on object: Any
    ) -> Any? {
        let reflection = Mirror(reflecting: object)
        return reflection.children
            .first(where: { $0.label == label })?
            .value
    }
}

extension OrderedSet {
    mutating func trimFront(softLimit: Int = 1000, buffer: Int = 500) {
        if count > softLimit + buffer {
            removeFirst(buffer)
        }
    }
}

extension String {
    private static let ocrMistakes = [
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
    
    func fuzzyFindPrefix(_ prefix: String, errorLimit: Double = 0.1) -> String? {
        var prefix = prefix
        
        for (standard, possibleChars) in Self.ocrMistakes {
            let regex = try! Regex("(\(possibleChars.joined(separator: "|")))")
            prefix = prefix.replacing(regex) { _ in standard }
        }
        
        let prefixCodeUnits = Array(prefix.utf16)
        let haystackCodeUnits = Array(self.utf16)
        
        guard prefixCodeUnits.count <= haystackCodeUnits.count else { return nil }
        
        let errorLimit = Int(Double(prefixCodeUnits.count) * errorLimit)
        var errorCount = 0
        var prefixIndex = 0
        var haystackIndex = 0
        var foundScalars: [Unicode.Scalar] = []
        
        while prefixIndex < prefixCodeUnits.count {
            guard let prefixChar = Unicode.Scalar(UInt32(prefixCodeUnits[prefixIndex])),
                  !CharacterSet.whitespaces.union(.punctuationCharacters).contains(prefixChar)
            else {
                prefixIndex += 1
                continue
            }
            
            guard let haystackChar = Unicode.Scalar(UInt32(haystackCodeUnits[haystackIndex]))
            else {
                haystackIndex += 1
                continue
            }
            
            guard !CharacterSet.whitespaces.union(.punctuationCharacters).contains(haystackChar)
            else {
                foundScalars.append(haystackChar)
                haystackIndex += 1
                continue
            }
            
            if haystackChar == prefixChar {
                foundScalars.append(haystackChar)
                continue
            }
            
            //check ocrMistakes, including multicharacter matches :(
            
            errorCount += 1
            if errorCount > errorLimit {
                return nil
            }
        }
        
        var foundString = ""
        foundString.unicodeScalars.append(contentsOf: foundScalars)
        
        return foundString
    }
}

