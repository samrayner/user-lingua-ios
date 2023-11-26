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
    var localizedString: LocalizedString
    var newValue: String
    var locale: Locale
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
        case previewingSuggestions
    }
    
    public struct Configuration {
        public var automaticallyOptInTextViews: Bool
        public var treatStringOnlyTextInitAsVerbatim: Bool
        public var locale: Locale
        
        public init(
            automaticallyOptInTextViews: Bool = true,
            treatStringOnlyTextInitAsVerbatim: Bool = true,
            locale: Locale = .current
        ) {
            self.automaticallyOptInTextViews = automaticallyOptInTextViews
            self.treatStringOnlyTextInitAsVerbatim = treatStringOnlyTextInitAsVerbatim
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
              let localizedString = localizedString(text: originalText)
        else { return originalText }
        
        if state == .recordingStrings {
            db.record(localizedString: localizedString)
        }
        
        return Text(verbatim: displayString(for: localizedString))
    }
    
    func displayString(for localizedString: LocalizedString) -> String {
        switch state {
        case .disabled, .highlightingStrings, .recordingStrings:
            return localizedString.value
        case .detectingStrings:
            guard let recordedString = db.recordedString(for: localizedString) else {
                return localizedString.value
            }
            return recordedString.detectable
        case .previewingSuggestions:
            guard let suggestion = db.suggestion(for: localizedString) else {
                return localizedString.value
            }
            return suggestion.newValue
        }
    }
    
    func displayString(for string: String) -> String {
        switch state {
        case .disabled, .highlightingStrings, .recordingStrings:
            return string
        case .detectingStrings:
            guard let recordedString = db.recordedString(for: string) else {
                return string
            }
            return recordedString.detectable
        case .previewingSuggestions:
            guard let suggestion = db.suggestion(for: string) else {
                return string
            }
            return suggestion.newValue
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
    
    private func localizedString(text: Text) -> LocalizedString? {
        guard let storage = Reflection.value("storage", on: text),
              let textStorage = Reflection.value("anyTextStorage", on: storage)
        else { return nil }
        
        switch "\(type(of: textStorage))" {
        case "LocalizedTextStorage":
            return localizedString(localizedTextStorage: textStorage)
        case "LocalizedStringResourceStorage":
            return localizedString(localizedStringResourceStorage: textStorage)
        case "AttributedStringTextStorage":
            //we probably want to support this in future
            return nil
        default:
            //there are more types we will probably never support
            return nil
        }
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
        guard let stringContainer = Reflection.value("key", on: storage)
        else { return nil }
        
        guard let key = Reflection.value("key", on: stringContainer) as? String
        else { return nil }
        
        let hasFormatting = Reflection.value("hasFormatting", on: stringContainer) as? Bool ?? false
        let bundle = Reflection.value("bundle", on: storage) as? Bundle
        let tableName = Reflection.value("table", on: storage) as? String
        let comment = Reflection.value("comment", on: storage) as? String
        
        var value = bundle?.localizedString(
            forKey: key,
            value: key,
            table: tableName
        ) ?? key
        
        if hasFormatting {
            let arguments = formattingArguments(stringContainer)
            value = String(format: value, arguments: arguments)
        }
        
        return LocalizedString(
            value: value,
            localization: .init(
                key: key,
                bundle: bundle,
                tableName: tableName,
                comment: comment
            )
        )
    }
    
    private func formattingArguments(_ container: Any) -> [CVarArg] {
        guard let arguments = Reflection.value("arguments", on: container) as? [Any]
        else { return [] }
        
        return arguments.compactMap(formattingArgument)
    }
        
    private func formattingArgument(_ container: Any) -> CVarArg? {
        guard let storage = Reflection.value("storage", on: container)
        else { return nil }
        
        if let textContainer = Reflection.value("text", on: storage),
           let text = Reflection.value(".0", on: textContainer) as? Text {
            return localizedString(text: text).map(displayString)
        }
        
        if let formatStyleContainer = Reflection.value("formatStyleValue", on: storage),
           let formatStyle = Reflection.value("format", on: formatStyleContainer) as? any FormatStyle,
           let input = Reflection.value("input", on: formatStyleContainer) {
            return formatStyle.string(for: input, locale: config.locale)
        }
        
        if let valueContainer = Reflection.value("value", on: storage),
           let value = Reflection.value(".0", on: valueContainer) as? CVarArg {
            let formatter = Reflection.value(".1", on: valueContainer) as? Formatter
            return formatter.flatMap { $0.string(for: value) } ?? value
        }
        
        return nil
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
    
    var suggestions: [String: [Suggestion]] = [:]
    
    func record(string: String) {
        stringRecord.append(RecordedString(string, localization: nil))
    }
    
    func record(localizedString: LocalizedString) {
        stringRecord.append(RecordedString(localizedString.value, localization: localizedString.localization))
    }
    
    private func suggestions(for oldValue: String) -> [Suggestion] {
        suggestions[oldValue, default: []].filter {
            $0.locale == .current
        }
    }
    
    func suggestion(for localizedString: LocalizedString) -> Suggestion? {
        let matchingValues = suggestions(for: localizedString.value)
        return matchingValues.last {
            $0.localizedString == localizedString
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

extension FormatStyle {
    func string(for input: Any, locale: Locale) -> String? {
        guard let input = input as? FormatInput else { return nil }
        let formatter = self.locale(locale)
        return formatter.format(input) as? String
    }
}
