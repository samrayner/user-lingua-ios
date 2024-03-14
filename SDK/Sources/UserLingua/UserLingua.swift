// UserLingua.swift

import ComposableArchitecture
import SwiftUI
import UIKit

public final class UserLingua {
    public static let shared = UserLingua()

    public let observableObject = UserLinguaObservableObject()

    private var shakeObservation: NSObjectProtocol?

    let stringsRepository: StringsRepositoryProtocol
    let suggestionsRepository: SuggestionsRepositoryProtocol
    let stringRecognizer: StringRecognizerProtocol
    let stringExtractor: StringExtractorProtocol
    private let stringProcessor: StringProcessorProtocol

    private var inPreviewsOrTests: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
            || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    let store = StoreOf<RootFeature>(initialState: .init()) {
        RootFeature()._printChanges()
    }

    private lazy var _window: UIWindow = {
        let window = UIApplication.shared.windowScene.map(UIWindow.init) ?? UIWindow(frame: UIScreen.main.bounds)
        window.isHidden = true
        window.backgroundColor = .clear
        window.rootViewController = UIHostingController(rootView: RootFeatureView(store: store))
        window.rootViewController?.view.backgroundColor = .clear
        window.windowLevel = .statusBar
        return window
    }()

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

    var mode: RootFeature.Mode.State {
        store.state.mode
    }

    public var configuration: UserLinguaConfiguration {
        store.state.configuration
    }

    func reloadViews() {
        observableObject.objectWillChange.send()
    }

    public func disable() {
        store.send(.didDisable)
    }

    public func configure(_ configuration: UserLinguaConfiguration) {
        store.send(.didConfigure(configuration))
    }

    public func enable() {
        guard !inPreviewsOrTests else { return }
        store.send(.didEnable)
    }

    func startObservingShake() {
        shakeObservation = NotificationCenter.default.addObserver(forName: .deviceDidShake, object: nil, queue: nil) { [weak self] _ in
            self?.store.send(.didShake)
        }
    }

    func stopObservingShake() {
        shakeObservation = nil
    }

    func processLocalizedStringKey(_ key: LocalizedStringKey) -> String {
        stringProcessor.processLocalizedStringKey(key, state: store.state)
    }

    func processString(_ string: String) -> String {
        stringProcessor.processString(string, state: store.state)
    }

    func displayString(for formattedString: FormattedString) -> String {
        stringProcessor.displayString(for: formattedString, state: store.state)
    }

    func formattedString(
        localizedStringKey: LocalizedStringKey,
        tableName: String?,
        bundle: Bundle?,
        comment: String?
    ) -> FormattedString {
        stringExtractor.formattedString(
            localizedStringKey: localizedStringKey,
            locale: store.state.locale,
            tableName: tableName,
            bundle: bundle,
            comment: comment
        )
    }

    func screenshotApp() -> UIImage? {
        guard let appWindow = appWindow() else { return nil }

        UIGraphicsBeginImageContextWithOptions(
            appWindow.layer.frame.size,
            false,
            UIScreen.main.scale
        )

        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        appWindow.layer.render(in: context)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return screenshot
    }

    func appWindow() -> UIWindow? {
        let windows = UIApplication.shared.windowScene?.windows.filter { $0 != _window }
        return windows?.first(where: \.isKeyWindow) ?? windows?.last
    }

    func window() -> UIWindow {
        _window.windowScene = UIApplication.shared.windowScene
        return _window
    }
}

extension UIApplication {
    var windowScene: UIWindowScene? {
        connectedScenes
            .first {
                $0 is UIWindowScene &&
                    $0.activationState == .foregroundActive
            }
            .flatMap { $0 as? UIWindowScene }
    }
}
