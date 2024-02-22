// UserLingua.swift

import SwiftUI
import SystemAPIAliases
import UIKit

public final class UserLingua: ObservableObject {
    enum State: Equatable {
        case disabled
        case recordingStrings
        case detectingStrings
        case highlightingStrings
        case previewingSuggestions
    }

    public struct Configuration {
        public var locale: Locale
        public var automaticallyOptInTextViews: Bool

        public init(
            locale: Locale = .current,
            automaticallyOptInTextViews: Bool = true
        ) {
            self.locale = locale
            self.automaticallyOptInTextViews = automaticallyOptInTextViews
        }
    }

    public static let shared = UserLingua()

    private var shakeObservation: NSObjectProtocol?

    let stringsRepository: StringsRepositoryProtocol
    let suggestionsRepository: SuggestionsRepositoryProtocol
    let textRecognizer: TextRecognizerProtocol
    let recognizedTextIdentifier: RecognizedTextIdentifierProtocol

    public var config = Configuration()
    var highlightedStrings: [RecordedString: [CGRect]] = [:] {
        didSet {
            DispatchQueue.main.async {
                self.state = .highlightingStrings
                self.displayHighlightedStrings()
            }
        }
    }

    private var inPreviewsOrTests: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
            || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    private var _state: State = .disabled {
        didSet {
            stateDidChange()
        }
    }

    var state: State {
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

    init(
        stringsRepository: StringsRepositoryProtocol = StringsRepository(),
        suggestionsRepository: SuggestionsRepositoryProtocol = SuggestionsRepository(),
        textRecognizer: TextRecognizerProtocol = TextRecognizer(),
        recognizedTextIdentifier: RecognizedTextIdentifierProtocol = RecognizedTextIdentifier()
    ) {
        self.stringsRepository = stringsRepository
        self.suggestionsRepository = suggestionsRepository
        self.textRecognizer = textRecognizer
        self.recognizedTextIdentifier = recognizedTextIdentifier
    }

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
    }

    private func swizzleUIKit() {
        Bundle.swizzle()
        UILabel.swizzle()
        UIButton.swizzle()
    }

    func processLocalizedStringKey(_ key: LocalizedStringKey) -> String {
        let localizedString = localizedString(localizedStringKey: key)

        if state == .recordingStrings {
            stringsRepository.record(localizedString: localizedString)
        }

        return displayString(for: localizedString)
    }

    func processString(_ string: String) -> String {
        if state == .recordingStrings {
            stringsRepository.record(string: string)
        }

        return displayString(for: string)
    }

    func displayString(for localizedString: LocalizedString) -> String {
        switch state {
        case .disabled, .highlightingStrings, .recordingStrings:
            return localizedString.value
        case .detectingStrings:
            guard let recordedString = stringsRepository.recordedString(localizedOriginal: localizedString) else {
                return localizedString.value
            }
            return recordedString.detectable
        case .previewingSuggestions:
            guard let suggestion = suggestionsRepository.suggestion(localizedOriginal: localizedString, locale: config.locale) else {
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
            guard let recordedString = stringsRepository.recordedString(original: string) else {
                return string
            }
            return recordedString.detectable
        case .previewingSuggestions:
            guard let suggestion = suggestionsRepository.suggestion(original: string, locale: config.locale) else {
                return string
            }
            return suggestion.newValue
        }
    }

    func didShake() {
        state = .detectingStrings
        // TODO: delay 0.1 seconds for SwiftUI to re-render
        let snapshot = snapshot(window: window!)!
        Task { [self] in
            let recognizedText = try await textRecognizer.recognizeText(in: snapshot)
            highlightedStrings = recognizedTextIdentifier
                .match(
                    recognizedText: recognizedText,
                    against: stringsRepository.recordedStrings()
                )
                .mapValues { $0.map(\.boundingBox) }
        }
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

    func localizedString(
        localizedStringKey: LocalizedStringKey,
        tableName: String? = nil,
        bundle: Bundle? = nil,
        comment: String? = nil
    ) -> LocalizedString {
        // swiftlint:disable:next force_cast
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

    private func snapshot(window: UIWindow) -> UIImage? {
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(window.layer.frame.size, false, scale)

        window.layer.render(in: UIGraphicsGetCurrentContext()!)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return screenshot
    }
}

extension FormatStyle {
    func string(for input: Any, locale: Locale) -> String? {
        guard let input = input as? FormatInput else { return nil }
        let formatter = self.locale(locale)
        return formatter.format(input) as? String
    }
}

extension UIApplication {
    var keyWindow: UIWindow? {
        connectedScenes
            .first {
                $0 is UIWindowScene &&
                    $0.activationState == .foregroundActive
            }
            .flatMap { $0 as? UIWindowScene }?
            .windows
            .first(where: \.isKeyWindow)
    }
}
