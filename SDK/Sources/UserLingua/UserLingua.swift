// UserLingua.swift

import CombineFeedback
import Core
import RootFeature
import SwiftUI
import UIKit

public typealias UserLinguaConfiguration = Core.Configuration

public final class UserLingua {
    public static let shared = UserLingua()

    public let viewModel = UserLinguaObservable()
    public private(set) var configuration: any ConfigurationProtocol = Configuration()
    private let windowService: WindowServiceProtocol = WindowService()
    private let contentSizeCategoryService: ContentSizeCategoryServiceProtocol = ContentSizeCategoryService()
    private let suggestionsRepository: SuggestionsRepositoryProtocol = SuggestionsRepository()
    private let stringsRepository: StringsRepositoryProtocol = StringsRepository()

    private lazy var store = RootFeature.store(
        initialState: .disabled,
        dependencies: .init(
            notificationCenter: .default,
            windowService: windowService,
            onForeground: onForeground,
            onBackground: onBackground
        )
    )

    private let stringExtractor: StringExtractorProtocol = StringExtractor()
    private let swizzler: SwizzlerProtocol = Swizzler()

    private var inPreviewsOrTests: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
            || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    private init() {
        windowService.setRootView(
            RootFeatureView(store: store)
                .environmentObject(configuration)
        )
    }

    var isTakingScreenshot: Bool {
        switch store.state {
        case let .visible(state):
            state.recognition.isTakingScreenshot
        default:
            false
        }
    }

    var appContentSizeCategory: UIContentSizeCategory {
        switch store.state {
        case .visible:
            contentSizeCategoryService.appContentSizeCategory
        default:
            contentSizeCategoryService.systemContentSizeCategory
        }
    }

    var window: UIWindow {
        windowService.userLinguaWindow
    }

    var isEnabled: Bool {
        store.state != .disabled
    }

    var isRecording: Bool {
        store.state == .recording
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
        self.configuration = configuration
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

    func processString(_ string: String) -> String {
        if isRecording {
            stringsRepository.record(string: string)
        }

        return displayString(for: FormattedString(string))
    }

    func displayString(for formattedString: FormattedString) -> String {
        if isTakingScreenshot {
            // if we've recorded this string, make the most detailed record
            // uniquely recognizable in the UI by scrambling it
            if let recordedString = stringsRepository.recordedString(formatted: formattedString) {
                return recordedString.recognizable
            }
            return formattedString.value
        }

        if case let .visible(state) = store.state, let state = state.inspection,
           !state.isTransitioning && state.recognizedString.value == formattedString.value {
            // we're currently inspecting this string so display the contents of the suggestion field
            return state.suggestionValue
        }

        // we're not currently interacting with this string so just display it
        return formattedString.value
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
