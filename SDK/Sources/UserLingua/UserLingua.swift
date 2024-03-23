// UserLingua.swift

import ComposableArchitecture
import Core
import RootFeature
import SwiftUI
import UIKit

public final class UserLingua {
    public static let shared = UserLingua()

    public let viewModel = UserLinguaObservable()
    private let windowManager: WindowManagerProtocol = WindowManager()
    private let suggestionsRepository: SuggestionsRepositoryProtocol = SuggestionsRepository()
    let stringsRepository: StringsRepositoryProtocol = StringsRepository()

    private lazy var stringRecognizer = StringRecognizer(
        stringsRepository: stringsRepository,
        windowManager: windowManager,
        appViewModel: viewModel
    )

    private lazy var store: StoreOf<RootFeature> = .init(
        initialState: .init(),
        reducer: { RootFeature() },
        withDependencies: {
            $0[UserLinguaObservableDependency.self] = self.viewModel
            $0[WindowManagerDependency.self] = self.windowManager
            $0[SuggestionsRepositoryDependency.self] = self.suggestionsRepository
            $0[StringsRepositoryDependency.self] = self.stringsRepository
            $0[StringRecognizerDependency.self] = self.stringRecognizer
        }
    )

    private let stringExtractor: StringExtractorProtocol = StringExtractor()
    private let swizzler: SwizzlerProtocol = Swizzler()
    private(set) lazy var triggerObserver: TriggerObserverProtocol = TriggerObserver(onShake: onShake)

    private var inPreviewsOrTests: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
            || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    private init() {
        windowManager.setRootView(
            RootFeatureView(
                store: store,
                stringRecognizer: stringRecognizer
            )
        )
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
        stringRecognizer.isTakingScreenshot
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
            if case let .inspection(state) = mode,
               state.recordedString.value == formattedString.value {
                // we're currently inspected this string so display the
                // suggestion the user is making if there is one
                if let suggestion = suggestionsRepository.suggestion(formatted: formattedString, locale: state.locale) {
                    return suggestion.newValue
                }

                // if there exists a localized record of this string, use that,
                // as the formattedString we have passed in might not be localized
                if let recordedString = stringsRepository.recordedString(formatted: formattedString) {
                    return recordedString.localizedValue(locale: state.locale)
                }

                // otherwise just display what we're given but localized
                // according to the current locale set in the inspector
                return formattedString.localizedValue(locale: state.locale)
            }

            if isTakingScreenshot {
                // if we've recorded this string, make the most detailed record
                // uniquely recognizable in the UI by scrambling it
                if let recordedString = stringsRepository.recordedString(formatted: formattedString) {
                    return recordedString.detectable
                }

                return formattedString.value
            }

            // we're not currently interacting with this string so just display it
            return formattedString.value
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
