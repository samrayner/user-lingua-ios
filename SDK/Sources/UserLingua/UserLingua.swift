// UserLingua.swift

import SwiftUI
import SystemAPIAliases
import UIKit
import Vision

struct RecordedString: Hashable {
    let original: String
    let detectable: String
    let localization: Localization?
    let recordedAt: Date = .now

    init(_ original: String, localization: Localization?) {
        self.original = original
        self.detectable = original.tokenized()
        self.localization = localization
    }

    var localizedString: LocalizedString? {
        localization.map { .init(value: original, localization: $0) }
    }
}

extension RecordedString: Identifiable {
    var id: String {
        original
    }
}

struct Suggestion {
    var recordedString: RecordedString
    var newValue: String
    var locale: Locale
    var createdAt: Date = .now
    var modifiedAt: Date = .now
    var isSubmitted = false
    var screenshot: UIImage?
}

public final class UserLingua: ObservableObject {
    package enum State: Equatable {
        case disabled
        case recordingStrings
        case detectingStrings
        case highlightingStrings
        case previewingSuggestions
    }

    public struct Configuration {
        public var locale: Locale

        public init(
            locale: Locale = .current
        ) {
            self.locale = locale
        }
    }

    public static let shared = UserLingua()

    private var shakeObservation: NSObjectProtocol?

    package let db = Database()
    public var config = Configuration()
    var highlightedStrings: [RecordedString: [CGRect]] = [:]

    private var inPreviewsOrTests: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
            || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    private var _state: State = .disabled {
        didSet {
            stateDidChange()
        }
    }

    package var state: State {
        get {
            guard !inPreviewsOrTests else { return .disabled }
            return _state
        }
        set {
            guard !inPreviewsOrTests else { return }
            _state = newValue
        }
    }

    var window: UIWindow? { UIApplication.shared.keyWindow }
    var newWindow: UIWindow?

    init() {}

    func refreshViews() {
        objectWillChange.send()
        NotificationCenter.default.post(name: .userLinguaObjectDidChange, object: nil)
    }

    public func enable(config: Configuration = .init()) {
        self.config = config
        state = .recordingStrings
        swizzleUIKit()
        shakeObservation = NotificationCenter.default.addObserver(forName: .deviceDidShake, object: nil, queue: nil) { [weak self] _ in
            self?.didShake()
        }
    }

    private func stateDidChange() {
        refreshViews()

        switch state {
        case .disabled, .recordingStrings, .detectingStrings, .highlightingStrings:
            stopObservingKeyboardHeight()
        case .previewingSuggestions:
            startObservingKeyboardHeight()
        }
    }

    private func startObservingKeyboardHeight() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    private func stopObservingKeyboardHeight() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc
    func keyboardWillShow(notification: Notification) {
        guard let keyboardHeight = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height else {
            return
        }

        window?.layer.transform = CATransform3DTranslate(CATransform3DIdentity, 0, -keyboardHeight, 0)
    }

    @objc
    func keyboardWillHide(notification _: Notification) {
        window?.layer.transform = CATransform3DTranslate(CATransform3DIdentity, 0, 0, 0)
    }

    private func swizzleUIKit() {
        Bundle.swizzle()
        UILabel.swizzle()
        UIButton.swizzle()
    }

    package func processLocalizedStringKey(_ key: LocalizedStringKey) -> String {
        let localizedString = localizedString(localizedStringKey: key)

        if state == .recordingStrings {
            db.record(localizedString: localizedString)
        }

        return displayString(for: localizedString)
    }

    package func processString(_ string: String) -> String {
        if state == .recordingStrings {
            db.record(string: string)
        }

        return displayString(for: string)
    }

    package func processText(_ originalText: Text) -> Text {
        guard state != .disabled else { return originalText }

        if let localizedString = localizedString(text: originalText) {
            if state == .recordingStrings {
                db.record(localizedString: localizedString)
            }

            return Text(verbatim: displayString(for: localizedString))
        }

        if let verbatim = verbatim(text: originalText) {
            return Text(verbatim: processString(verbatim))
        }

        return originalText
    }

    package func displayString(for localizedString: LocalizedString) -> String {
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
        state = .detectingStrings
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.recognizeText()
            self.displayHighlightedStrings()
        }
    }

    private func rectForTextBlock(_ textBlock: VNRecognizedText) -> CGRect {
        let stringRange = textBlock.string.startIndex ..< textBlock.string.endIndex
        let box = try? textBlock.boundingBox(for: stringRange)
        let boundingBox = box?.boundingBox ?? .zero
        return VNImageRectForNormalizedRect(boundingBox, Int(UIScreen.main.bounds.width), Int(UIScreen.main.bounds.height))
    }

    private func displayHighlightedStrings() {
        newWindow = UIWindow(windowScene: window!.windowScene!)
        newWindow?.backgroundColor = .clear
        newWindow?.rootViewController = UIHostingController(rootView: HighlightsView())
        newWindow?.rootViewController?.view.backgroundColor = .clear
        newWindow?.windowLevel = .statusBar
        newWindow?.makeKeyAndVisible()
    }

    private func verbatim(text: Text) -> String? {
        guard let storage = Reflection.value("storage", on: text)
        else { return nil }

        return Reflection.value("verbatim", on: storage) as? String
    }

    private func localizedString(text: Text) -> LocalizedString? {
        guard let storage = Reflection.value("storage", on: text),
              let textStorage = Reflection.value("anyTextStorage", on: storage)
        else { return nil }

        return switch "\(type(of: textStorage))" {
        case "LocalizedTextStorage":
            localizedString(localizedTextStorage: textStorage)
        case "LocalizedStringResourceStorage":
            localizedString(localizedStringResourceStorage: textStorage)
        case "AttributedStringTextStorage":
            // we probably want to support this in future
            nil
        default:
            // there are more types we will probably never support
            nil
        }
    }

    private func localizedString(localizedStringResourceStorage storage: Any) -> LocalizedString? {
        guard let resource = Reflection.value("resource", on: storage) as? LocalizedStringResource
        else { return nil }

        let bundleURL = Reflection.value("_bundleURL", on: resource) as? URL
        let localeIdentifier = resource.locale.identifier

        let bundle = (bundleURL.flatMap(Bundle.init(url:)) ?? .main).path(
            forResource: localeIdentifier.replacingOccurrences(of: "_", with: "-"),
            ofType: "lproj"
        )
        .flatMap(Bundle.init(path:))

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

    package func localizedString(
        localizedStringKey: LocalizedStringKey,
        tableName: String? = nil,
        bundle: Bundle? = nil,
        comment: String? = nil
    ) -> LocalizedString {
        let key = Reflection.value("key", on: localizedStringKey) as! String

        let hasFormatting = Reflection.value("hasFormatting", on: localizedStringKey) as? Bool ?? false

        var value = (bundle ?? .main).unswizzledLocalizedString(
            forKey: key,
            value: key,
            table: tableName
        )

        if hasFormatting {
            let arguments = formattingArguments(localizedStringKey)
            value = SystemString.initFormatLocaleArguments(value, nil, arguments)
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

    private func localizedString(localizedTextStorage storage: Any) -> LocalizedString? {
        guard let localizedStringKey = Reflection.value("key", on: storage) as? LocalizedStringKey
        else { return nil }

        let bundle = Reflection.value("bundle", on: storage) as? Bundle
        let tableName = Reflection.value("table", on: storage) as? String
        let comment = Reflection.value("comment", on: storage) as? String

        return localizedString(
            localizedStringKey: localizedStringKey,
            tableName: tableName,
            bundle: bundle,
            comment: comment
        )
    }

    private func formattingArguments(_ localizedStringKey: LocalizedStringKey) -> [CVarArg] {
        guard let arguments = Reflection.value("arguments", on: localizedStringKey) as? [Any]
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
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale)

        layer.render(in: UIGraphicsGetCurrentContext()!)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return screenshot
    }

    public func recognizeText() {
        guard let uiImage = snapshot(),
              let cgImage = uiImage.cgImage else { return }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
        request.recognitionLevel = .fast
        request.automaticallyDetectsLanguage = false
        request.usesLanguageCorrection = false

        let minimumTextPixelHeight: Double = 6
        request.minimumTextHeight = Float(minimumTextPixelHeight / uiImage.size.height)

        do {
            try requestHandler.perform([request])
        } catch {
            print("Unable to perform the requests: \(error).")
        }
    }

    private func recognizeTextHandler(request: VNRequest, error _: Error?) {
        guard let observations = request.results as? [VNRecognizedTextObservation]
        else { return }

        let recognizedText = observations
            .compactMap { observation in
                observation.topCandidates(1).first
            }

        highlightedStrings = matchRecognizedTextToKnownStrings(recognizedText).mapValues { $0.map(rectForTextBlock) }
        state = .highlightingStrings
    }

    private func matchRecognizedTextToKnownStrings(
        _ recognizedText: [VNRecognizedText]
    ) -> [RecordedString: [VNRecognizedText]] {
        let recordedStrings = db.stringRecord
            .flatMap { $0.value }
            .sorted { $0.recordedAt > $1.recordedAt }

        var textBlocks = recognizedText
        var matches: [RecordedString: [VNRecognizedText]] = [:]

        // loop recognized text blocks
        while var textBlock = textBlocks.first {
            var recordedStringFoundForTextBlock = false

            for recordedString in recordedStrings {
                var tokenized = recordedString.detectable

                // while the text block is found at the start of the token
                while let foundPrefix = tokenized.fuzzyFindPrefix(textBlock.string) {
                    recordedStringFoundForTextBlock = true

                    // remove the text block from start of the token
                    tokenized = tokenized
                        .dropFirst(foundPrefix.count)
                        .trimmingCharacters(in: .whitespaces)

                    // assign the text block to the token it was found in
                    // and remove it from the text blocks we're looking for
                    matches[recordedString, default: []].append(textBlock)

                    textBlocks.removeFirst()

                    if let nextTextBlock = textBlocks.first {
                        textBlock = nextTextBlock
                    } else {
                        // we've processed all text blocks, so we're done
                        return matches
                    }
                }
            }

            if !recordedStringFoundForTextBlock {
                // no matches found for text block, so give up and move onto next
                textBlocks.removeFirst()
            }
        }

        return matches
    }
}

package final class Database {
    var stringRecord: [String: [RecordedString]] = [:]

    var suggestions: [String: [Suggestion]] = [:]

    func record(string: String) {
        stringRecord[string, default: []].append(RecordedString(string, localization: nil))
    }

    package func record(localizedString: LocalizedString) {
        guard localizedString.localization.bundle?.bundleURL.lastPathComponent != "UIKitCore.framework"
        else { return }

        let recordedString = RecordedString(
            localizedString.value,
            localization: localizedString.localization
        )

        stringRecord[localizedString.value, default: []].append(recordedString)
    }

    private func suggestions(for oldValue: String) -> [Suggestion] {
        suggestions[oldValue, default: []].filter {
            $0.locale == .current
        }
    }

    func suggestion(for localizedString: LocalizedString) -> Suggestion? {
        let matchingValues = suggestions(for: localizedString.value)
        return matchingValues.last {
            $0.recordedString.localizedString == localizedString
        } ?? matchingValues.last
    }

    func suggestion(for oldValue: String) -> Suggestion? {
        suggestions(for: oldValue).first
    }

    private func recordedStrings(for original: String) -> [RecordedString] {
        stringRecord[original] ?? []
    }

    func recordedString(for localizedString: LocalizedString) -> RecordedString? {
        let matchingValues = recordedStrings(for: localizedString.value)
        return matchingValues.last {
            $0.localization == localizedString.localization
        } ?? matchingValues.last
    }

    func recordedString(for original: String) -> RecordedString? {
        let recorded = recordedStrings(for: original)
        return recorded.last { $0.localization != nil } ?? recorded.last
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

    func fuzzyFindPrefix(_ prefix: String, errorLimit: Double = 0.1) -> String? {
        let haystack = self

        var prefix = prefix

        // swap out all potentially misrecognized substrings with
        // the most likely character they could have been
        for (standard, possibleChars) in ocrMistakes {
            let regex = try! Regex("(\(possibleChars.joined(separator: "|")))")
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

        func findNextCharacters() -> [UTF16Char] {
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

        while prefixIndex < prefixUTF16Chars.count && haystackIndex < haystackUTF16Chars.count {
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

extension FormatStyle {
    func string(for input: Any, locale: Locale) -> String? {
        guard let input = input as? FormatInput else { return nil }
        let formatter = self.locale(locale)
        return formatter.format(input) as? String
    }
}

extension UTF16Char {
    var unicodeScalar: Unicode.Scalar? {
        Unicode.Scalar(UInt32(self))
    }
}

extension UIApplication {
    var keyWindow: UIWindow? {
        connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .first(where: { $0 is UIWindowScene })
            .flatMap({ $0 as? UIWindowScene })?.windows
            .first(where: \.isKeyWindow)
    }
}
