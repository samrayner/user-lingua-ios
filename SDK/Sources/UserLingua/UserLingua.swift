import UIKit
import SwiftUI
import OrderedCollections
import Vision

struct Localization: Hashable {
    var key: String
    var bundle: Bundle?
    var tableName: String?
    var comment: String?
}

struct LocalizedString: Hashable {
    var value: String
    var localization: Localization
}

struct RecordedString: Hashable {
    let original: String
    let detectable: String
    let localization: Localization?
    
    init(_ original: String, localization: Localization?) {
        self.original = original
        self.detectable = original.tokenized()
        self.localization = localization
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

final public class UserLingua: ObservableObject {
    enum State {
        case disabled
        case recordingStrings
        case detectingStrings
        case highlightingStrings
        case previewingSuggestion
    }
    
    public struct Configuration {
        public var automaticallyOptInLocalizedTextViews: Bool
        public var locale: Locale
        
        public init(
            automaticallyOptInLocalizedTextViews: Bool = true,
            locale: Locale = .current
        ) {
            self.automaticallyOptInLocalizedTextViews = automaticallyOptInLocalizedTextViews
            self.locale = locale
        }
    }
    
    public static let shared = UserLingua()
    
    let db = Database()
    public var config = Configuration()
    
    var state: State = .disabled {
        willSet {
            if newValue != state {
                objectWillChange.send()
            }
        }
    }
    
    var window: UIWindow?
    
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
        var string: LocalizedString?
        
        switch textStorageType {
        case "LocalizedTextStorage":
            string = localizedString(localizedTextStorage: textStorage)
        case "LocalizedStringResourceStorage":
            string = localizedString(localizedStringResourceStorage: textStorage)
        case "AttributedStringTextStorage":
            //we probably want to support this in future
            return originalText
        default:
            //there are more types we will probably never support
            return originalText
        }
        
        guard let localizedString = string else { return originalText }
        
        switch state {
        case .disabled, .highlightingStrings:
            return originalText
        case .recordingStrings:
            db.record(localizedString: localizedString)
            return originalText
        case .detectingStrings:
            guard let recordedString = db.recordedString(for: localizedString) else {
                return originalText
            }
            return .init(verbatim: recordedString.detectable)
        case .previewingSuggestion:
            guard let suggestion = db.suggestion(for: localizedString) else {
                return originalText
            }
            return .init(verbatim: suggestion.newValue)
        }
    }
    
    func didShake() {
        let previousState = state
        state = .detectingStrings
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.findAllText()
            self.state = previousState
        }
    }
    
    func setWindow(_ window: UIWindow?) {
        self.window = window
    }
    
    private func localizedString(localizedStringResourceStorage storage: Any) -> LocalizedString? {
        guard let resource = Reflection.value("resource", on: storage) as? LocalizedStringResource
        else { return nil }
        
        let bundleURL = Reflection.value("_bundleURL", on: resource) as? URL
        let localeIdentifier = resource.locale.identifier
        
        let bundle = (bundleURL.map(Bundle.init(url:)) ?? .main)?.path(
            forResource: localeIdentifier.replacingOccurrences(of: "_", with: "-"),
            ofType: "lproj"
        )
        .flatMap { Bundle(path: $0) }
        
        return LocalizedString(
            value: String(localized: resource),
            localization: .init(
                key: resource.key,
                bundle: bundle,
                tableName: resource.table,
                comment: nil
            )
        )
    }
    
    private func localizedString(localizedTextStorage storage: Any) -> LocalizedString? {
        guard let keyStorage = Reflection.value("key", on: storage) as? String
        else { return nil }
        
        guard let key = Reflection.value("key", on: keyStorage) as? String
        else { return nil }
        
        let storageBundle = Reflection.value("bundle", on: storage) as? Bundle
        let tableName = Reflection.value("table", on: storage) as? String
        let comment = Reflection.value("comment", on: storage) as? String
        
        let localeIdentifier = UserLingua.shared.config.locale.identifier
        
        let bundle = (storageBundle ?? .main)?.path(
            forResource: localeIdentifier.replacingOccurrences(of: "_", with: "-"),
            ofType: "lproj"
        )
        .flatMap({ Bundle(path: $0) })
        
        let value = bundle?.localizedString(forKey: key, value: key, table: tableName)
        
        return LocalizedString(
            value: value ?? key,
            localization: .init(
                key: key,
                bundle: bundle,
                tableName: tableName,
                comment: comment
            )
        )
    }
    
    private func snapshot() -> UIImage? {
        guard let layer = window?.layer else { return nil }
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale);

        layer.render(in: UIGraphicsGetCurrentContext()!)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return screenshot
    }
    
    public func findAllText() {
        guard let uiImage = snapshot(),
              let cgImage = uiImage.cgImage else { return }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
        request.recognitionLevel = .fast
        request.automaticallyDetectsLanguage = false
        request.usesLanguageCorrection = false
        
        let minimumTextPixelHeight: Double = 8
        request.minimumTextHeight = Float(minimumTextPixelHeight / uiImage.size.height)
        
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
    ) -> [RecordedString: [VNRecognizedText]] {
        var textBlocks = recognizedText
        var matches: [RecordedString: [VNRecognizedText]] = [:]
        
        //loop recognized text blocks
        while var textBlock = textBlocks.first {
            var recordedStringFoundForTextBlock = false
            
            for recordedString in db.stringRecord where matches[recordedString] == nil {
                var tokenized = recordedString.detectable
                
                //while the text block is found at the start of the token
                while let foundPrefix = tokenized.fuzzyFindPrefix(textBlock.string) {
                    recordedStringFoundForTextBlock = true
                    
                    //remove the text block from start of the token
                    tokenized = tokenized
                        .dropFirst(foundPrefix.count)
                        .trimmingCharacters(in: .whitespaces)
                    
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
    var stringRecord: [RecordedString] = [] {
        didSet { stringRecord.trimFront() }
    }
    
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
        let tokenized = RecordedString(string, localization: nil)
        stringRecord.append(tokenized)
    }
    
    func record(localizedString: LocalizedString) {
        record(string: localizedString.value)
    }
    
    private func suggestions(for oldValue: String) -> [Suggestion] {
        suggestions[oldValue, default: []].filter {
            $0.locale == .current
        }
    }
    
    func suggestion(for localizedString: LocalizedString) -> Suggestion? {
        let matchingValues = suggestions(for: localizedString.value)
        return matchingValues.last {
            $0.localization == localizedString.localization
        } ?? matchingValues.last
    }
    
    func suggestion(for oldValue: String) -> Suggestion? {
        suggestions(for: oldValue).first
    }
    
    private func recordedStrings(for original: String) -> [RecordedString] {
        stringRecord.filter { $0.original == original }
    }
    
    func recordedString(for localizedString: LocalizedString) -> RecordedString? {
        let matchingValues = recordedStrings(for: localizedString.value)
        return matchingValues.last {
            $0.localization == localizedString.localization
        } ?? matchingValues.last
    }
    
    func recordedString(for original: String) -> RecordedString? {
        recordedStrings(for: original).last
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

extension Array {
    mutating func trimFront(softLimit: Int = 1000, buffer: Int = 500) {
        if count > softLimit + buffer {
            removeFirst(buffer)
        }
    }
}

extension String {
    private var ocrMistakes: [String: [String]] {
        [
            "l": ["I", "1"],
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
    
    func fuzzyFindPrefix(_ prefix: String, errorLimit: Double = 0.1) -> String? {
        let haystack = self
        
        //keep only word characters in the string we're finding
        var prefix = prefix.replacing(#/[\W_]/#) { _ in "" }

        //swap out all potentially misrecognized substrings with
        //the most likely character they could have been
        for (standard, possibleChars) in ocrMistakes {
            let regex = try! Regex("(\(possibleChars.joined(separator: "|")))")
            prefix = prefix.replacing(regex) { _ in standard }
        }
        
        let prefixUTF16Chars = Array(prefix.utf16)
        let haystackUTF16Chars = Array(haystack.utf16)
        
        //if the prefix is still longer than the full string, there's no way
        guard prefixUTF16Chars.count <= haystackUTF16Chars.count else { return nil }
        
        let errorLimit = Int(Double(prefixUTF16Chars.count) * errorLimit)
        var errorCount = 0
        var prefixIndex = 0
        var haystackIndex = 0
        var foundPrefix: [UTF16Char] = []
        
        func findNextCharacters() -> [UTF16Char] {
            let prefixUTF16Char = prefixUTF16Chars[prefixIndex]
            let haystackUTF16Char = haystackUTF16Chars[haystackIndex]
            
            // return whitespace and punctuation characters as found
            // but don't advance the prefix cursor as they have already
            // been removed from the prefix
            guard let haystackChar = haystackUTF16Char.unicodeScalar,
                  !CharacterSet.whitespaces
                    .union(.punctuationCharacters)
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
            
            if haystackUTF16Char == prefixUTF16Char {
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
                    let haystackPrefixChars = Array(haystackUTF16Chars[haystackIndex...rangeEnd])
                    
                    if haystackPrefixChars == alternativeChars {
                        return haystackPrefixChars
                    }
                }
            }
            
            return []
        }
        
        while prefixIndex < prefixUTF16Chars.count {
            let foundChars = findNextCharacters()
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
