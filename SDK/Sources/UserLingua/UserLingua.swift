// UserLingua.swift

import ComposableArchitecture
import SwiftUI
import UIKit

public final class UserLingua {
    public static let shared = UserLingua()

    public let viewModel = UserLinguaObservable()

    let windowManager: WindowManagerProtocol
    let suggestionsRepository: SuggestionsRepositoryProtocol
    let stringsRepository: StringsRepositoryProtocol
    let stringRecognizer: StringRecognizerProtocol
    let stringExtractor: StringExtractorProtocol
    private let stringProcessor: StringProcessorProtocol

    private var inPreviewsOrTests: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
            || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    lazy var store: StoreOf<RootFeature> = .init(
        initialState: .init(),
        reducer: { RootFeature() },
        withDependencies: {
            $0[TriggerObserverDependency.self] = TriggerObserver(
                onShake: { self.onShake() }
            )

            $0[WindowManagerDependency.self] = self.windowManager
            $0[StringRecognizerDependency.self] = self.stringRecognizer
            $0[SuggestionsRepositoryDependency.self] = self.suggestionsRepository
        }
    )

    init() {
        self.windowManager = WindowManager()
        self.suggestionsRepository = SuggestionsRepository()
        self.stringsRepository = StringsRepository()
        self.stringExtractor = StringExtractor()
        self.stringRecognizer = StringRecognizer(stringsRepository: stringsRepository)
        self.stringProcessor = StringProcessor(
            stringExtractor: stringExtractor,
            stringsRepository: stringsRepository,
            suggestionsRepository: suggestionsRepository
        )

        windowManager.setRootView(RootFeatureView(store: store))
    }

    var mode: RootFeature.Mode.State {
        store.mode
    }

    public var configuration: UserLinguaConfiguration {
        store.configuration
    }

    public func disable() {
        store.send(.disable)
    }

    public func configure(_ configuration: UserLinguaConfiguration) {
        store.send(.configure(configuration))
    }

    public func enable() {
        guard !inPreviewsOrTests else { return }
        store.send(.enable)
    }

    private func onShake() {
        store.send(.didShake)
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
            locale: store.locale,
            tableName: tableName,
            bundle: bundle,
            comment: comment
        )
    }
}
