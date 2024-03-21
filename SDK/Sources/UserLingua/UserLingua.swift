// UserLingua.swift

import ComposableArchitecture
import Core
import RootFeature
import SwiftUI
import UIKit

public final class UserLingua {
    public static let shared = UserLingua()

    public let viewModel = UserLinguaObservable()

    let windowManager: WindowManagerProtocol = WindowManager()
    let suggestionsRepository: SuggestionsRepositoryProtocol = SuggestionsRepository()
    let stringsRepository: StringsRepositoryProtocol = StringsRepository()
    let stringExtractor: StringExtractorProtocol = StringExtractor()
    let swizzler: SwizzlerProtocol = Swizzler()

    private(set) lazy var triggerObserver: TriggerObserverProtocol = TriggerObserver(onShake: onShake)

    private var inPreviewsOrTests: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
            || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    lazy var store: StoreOf<RootFeature> = .init(
        initialState: .init(),
        reducer: { RootFeature() },
        withDependencies: {
            $0[WindowManagerDependency.self] = self.windowManager
            $0[SuggestionsRepositoryDependency.self] = self.suggestionsRepository
            $0[StringsRepositoryDependency.self] = self.stringsRepository
        }
    )

    private init() {
        windowManager.setRootView(RootFeatureView(store: store))
    }

    private var mode: RootFeature.Mode.State {
        _PerceptionLocals.$skipPerceptionChecking.withValue(true) {
            store.mode
        }
    }

    public var configuration: UserLinguaConfiguration {
        _PerceptionLocals.$skipPerceptionChecking.withValue(true) {
            store.configuration.userLinguaConfiguration
        }
    }

    var isTakingScreenshot: Bool {
        _PerceptionLocals.$skipPerceptionChecking.withValue(true) {
            switch store.mode {
            case let .selection(state) where state.stage == .takingScreenshot:
                true
            default:
                false
            }
        }
    }

    var isEnabled: Bool {
        _PerceptionLocals.$skipPerceptionChecking.withValue(true) {
            mode != .disabled
        }
    }

    var isRecording: Bool {
        _PerceptionLocals.$skipPerceptionChecking.withValue(true) {
            mode == .recording
        }
    }

    public func enable() {
        guard !inPreviewsOrTests else { return }
        swizzler.swizzle()
        triggerObserver.startObservingShake()
        store.send(.enable)
    }

    public func disable() {
        store.send(.disable)
        swizzler.unswizzle()
        triggerObserver.stopObservingShake()
    }

    public func configure(_ configuration: UserLinguaConfiguration) {
        store.send(.configure(Configuration(configuration)))
    }

    private func onShake() {
        store.send(.didShake)
    }

    func processLocalizedStringKey(_ key: LocalizedStringKey) -> String {
        _PerceptionLocals.$skipPerceptionChecking.withValue(true) {
            let formattedString = stringExtractor.formattedString(
                localizedStringKey: key,
                tableName: nil,
                bundle: nil,
                comment: nil
            )

            if isRecording {
                stringsRepository.record(formatted: formattedString)
            }

            return displayString(for: formattedString)
        }
    }

    func processString(_ string: String) -> String {
        _PerceptionLocals.$skipPerceptionChecking.withValue(true) {
            if isRecording {
                stringsRepository.record(string: string)
            }

            return displayString(for: FormattedString(string))
        }
    }

    func displayString(for formattedString: FormattedString) -> String {
        _PerceptionLocals.$skipPerceptionChecking.withValue(true) {
            switch mode {
            case let .selection(state) where state.stage == .takingScreenshot:
                guard let recordedString = stringsRepository.recordedString(formatted: formattedString) else {
                    return formattedString.value
                }
                return recordedString.detectable
            case let .inspection(state) where state.recordedString.value == formattedString.value:
                guard let suggestion = suggestionsRepository.suggestion(formatted: formattedString, locale: state.locale) else {
                    return formattedString.localizedValue(locale: state.locale)
                }
                return suggestion.newValue
            default:
                return formattedString.value
            }
        }
    }

    func formattedString(
        localizedStringKey: LocalizedStringKey,
        tableName: String?,
        bundle: Bundle?,
        comment: String?
    ) -> FormattedString {
        stringExtractor.formattedString(
            localizedStringKey: localizedStringKey,
            tableName: tableName,
            bundle: bundle,
            comment: comment
        )
    }
}
