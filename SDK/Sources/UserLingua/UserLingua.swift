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
        case previewingSuggestions(locale: Locale)

        var locale: Locale {
            switch self {
            case .disabled, .recordingStrings, .detectingStrings, .highlightingStrings:
                .current
            case let .previewingSuggestions(locale):
                locale
            }
        }
    }

    public struct Configuration {
        public var automaticallyOptInTextViews: Bool

        public init(
            automaticallyOptInTextViews: Bool = true
        ) {
            self.automaticallyOptInTextViews = automaticallyOptInTextViews
        }
    }

    public static let shared = UserLingua()

    private var shakeObservation: NSObjectProtocol?

    let stringsRepository: StringsRepositoryProtocol
    let suggestionsRepository: SuggestionsRepositoryProtocol
    let stringRecognizer: StringRecognizerProtocol
    let stringExtractor: StringExtractorProtocol
    private let stringProcessor: StringProcessorProtocol

    public var config = Configuration()
    var highlightedStrings: [(RecordedString, [RecognizedText])] = [] {
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

    init() {
        self.stringsRepository = StringsRepository()
        self.suggestionsRepository = SuggestionsRepository()
        self.stringExtractor = StringExtractor()
        self.stringRecognizer = StringRecognizer(stringsRepository: stringsRepository)
        self.stringProcessor = StringProcessor(
            stringExtractor: stringExtractor,
            stringsRepository: stringsRepository,
            suggestionsRepository: suggestionsRepository
        )
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
        stringProcessor.processLocalizedStringKey(key, state: state)
    }

    func processString(_ string: String) -> String {
        stringProcessor.processString(string, state: state)
    }

    func displayString(for formattedString: FormattedString) -> String {
        stringProcessor.displayString(for: formattedString, state: state)
    }

    func formattedString(
        localizedStringKey: LocalizedStringKey,
        tableName: String?,
        bundle: Bundle?,
        comment: String?
    ) -> FormattedString {
        stringExtractor.formattedString(
            localizedStringKey: localizedStringKey,
            locale: state.locale,
            tableName: tableName,
            bundle: bundle,
            comment: comment
        )
    }

    func didShake() {
        state = .detectingStrings
        // TODO: delay 0.1 seconds for SwiftUI to re-render
        let snapshot = snapshot(window: window!)!
        Task { [self] in
            highlightedStrings = try await stringRecognizer.recognizeStrings(in: snapshot)
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

    private func snapshot(window: UIWindow) -> UIImage? {
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(window.layer.frame.size, false, scale)

        window.layer.render(in: UIGraphicsGetCurrentContext()!)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return screenshot
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
