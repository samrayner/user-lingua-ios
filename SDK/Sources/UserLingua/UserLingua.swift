// UserLingua.swift

import ComposableArchitecture
import Core
import RootFeature
import SwiftUI
import UIKit

public typealias UserLinguaConfiguration = Core.Configuration

public final class UserLingua {
    public static let shared = UserLingua()

    public let viewModel = UserLinguaObservable()
    private let windowManager: WindowManagerProtocol = WindowManager()
    private let contentSizeCategoryManager: ContentSizeCategoryManagerProtocol = ContentSizeCategoryManager()
    private let suggestionsRepository: SuggestionsRepositoryProtocol = SuggestionsRepository()
    private let stringsRepository: StringsRepositoryProtocol = StringsRepository()

    private lazy var store: StoreOf<RootFeature> = .init(
        initialState: .init(),
        reducer: {
            RootFeature(
                onForeground: onForeground,
                onBackground: onBackground
            )
        },
        withDependencies: {
            $0[UserLinguaObservableDependency.self] = self.viewModel
            $0[WindowManagerDependency.self] = self.windowManager
            $0[ContentSizeCategoryManagerDependency.self] = self.contentSizeCategoryManager
            $0[SuggestionsRepositoryDependency.self] = self.suggestionsRepository
            $0[StringsRepositoryDependency.self] = self.stringsRepository
        }
    )

    private let stringExtractor: StringExtractorProtocol = StringExtractor()
    private let swizzler: SwizzlerProtocol = Swizzler()

    private var inPreviewsOrTests: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
            || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    private init() {
        windowManager.setRootView(RootFeatureView(store: store))
    }

    public var configuration: Configuration {
        _PerceptionLocals.$skipPerceptionChecking.withValue(true) {
            store.configuration
        }
    }

    var isTakingScreenshot: Bool {
        _PerceptionLocals.$skipPerceptionChecking.withValue(true) {
            switch store.mode {
            case let .visible(state):
                state.recognition.isTakingScreenshot
            default:
                false
            }
        }
    }

    var appContentSizeCategory: UIContentSizeCategory {
        _PerceptionLocals.$skipPerceptionChecking.withValue(true) {
            switch store.mode {
            case .visible:
                contentSizeCategoryManager.appContentSizeCategory
            default:
                contentSizeCategoryManager.systemContentSizeCategory
            }
        }
    }

    var window: UIWindow {
        windowManager.userLinguaWindow
    }

    var isEnabled: Bool {
        _PerceptionLocals.$skipPerceptionChecking.withValue(true) {
            store.mode != .disabled
        }
    }

    var isRecording: Bool {
        _PerceptionLocals.$skipPerceptionChecking.withValue(true) {
            store.mode == .recording
        }
    }

    public func enable() {
        guard !inPreviewsOrTests else { return }
        swizzler.swizzleForBackground()
        store.send(.enable)
    }

    public func disable() {
        store.send(.disable)
        swizzler.unswizzleForBackground()
    }

    public func configure(_ configuration: Configuration) {
        store.send(.configure(configuration))
    }

    private func onForeground() {
        swizzler.swizzleForForeground()
    }

    private func onBackground() {
        swizzler.unswizzleForForeground()
    }

    func record(formatted: FormattedString) {
        guard isRecording else { return }
        stringsRepository.record(formatted: formatted)
    }

    func record(localized: LocalizedString) {
        guard isRecording else { return }
        stringsRepository.record(localized: localized)
    }

    func record(string: String) {
        guard isRecording else { return }
        stringsRepository.record(string: string)
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
            if isTakingScreenshot {
                // if we've recorded this string, make the most detailed record
                // uniquely recognizable in the UI by scrambling it
                if let recordedString = stringsRepository.recordedString(formatted: formattedString) {
                    return recordedString.recognizable
                }
                return formattedString.value
            }

            if case let .visible(state) = store.mode, let state = state.inspection,
               state.appFacade == nil && state.recognizedString.value == formattedString.value {
                // we're currently inspected this string so display the
                // suggestion the user is making if there is one
                if let suggestion = suggestionsRepository.suggestion(for: formattedString.value, locale: state.locale) {
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
