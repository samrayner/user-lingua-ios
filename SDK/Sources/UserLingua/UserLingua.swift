// UserLingua.swift

import CombineFeedback
import Core
import Dependencies
import RootFeature
import SwiftUI
import UIKit

public typealias UserLinguaConfiguration = Core.Configuration

public final class UserLingua {
    public static let shared = UserLingua()
    private let dependencies: AllDependencies
    public private(set) var configuration: Configuration = Configuration()

    private lazy var store = RootFeature.store(
        initialState: .disabled,
        dependencies: .init(dependencies: dependencies)
    )

    private var inPreviewsOrTests: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
            || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    public var viewModel: UserLinguaObservable {
        dependencies.appViewModel
    }

    private init(
        dependencies: AllDependencies = LiveDependencies(swizzler: Swizzler())
    ) {
        self.dependencies = dependencies

        dependencies.windowService.setRootView(
            RootFeatureView(store: store)
                .environmentObject(ObservableWrapper(configuration))
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
            dependencies.contentSizeCategoryService.appContentSizeCategory
        default:
            dependencies.contentSizeCategoryService.systemContentSizeCategory
        }
    }

    var window: UIWindow {
        dependencies.windowService.userLinguaWindow
    }

    var isEnabled: Bool {
        store.state != .disabled
    }

    var isRecording: Bool {
        store.state == .recording
    }

    public func enable() {
        guard !inPreviewsOrTests else { return }
        dependencies.swizzler.swizzleForBackground()
        store.send(.enable)
    }

    public func disable() {
        store.send(.disable)
        dependencies.swizzler.unswizzleForBackground()
    }

    public func configure(_ configuration: Configuration) {
        self.configuration = configuration
    }

    func record(formatted: FormattedString) {
        guard isRecording else { return }
        dependencies.stringsRepository.record(formatted: formatted)
    }

    func record(localized: LocalizedString) {
        guard isRecording else { return }
        dependencies.stringsRepository.record(localized: localized)
    }

    func record(string: String) {
        guard isRecording else { return }
        dependencies.stringsRepository.record(string: string)
    }

    func processLocalizedStringKey(_ key: LocalizedStringKey) -> String {
        let formattedString = dependencies.stringExtractor.formattedString(
            localizedStringKey: key,
            tableName: nil,
            bundle: nil,
            comment: nil
        )

        if isRecording {
            dependencies.stringsRepository.record(formatted: formattedString)
        }

        return displayString(for: formattedString)
    }

    func processString(_ string: String) -> String {
        if isRecording {
            dependencies.stringsRepository.record(string: string)
        }

        return displayString(for: FormattedString(string))
    }

    func displayString(for formattedString: FormattedString) -> String {
        if isTakingScreenshot {
            // if we've recorded this string, make the most detailed record
            // uniquely recognizable in the UI by scrambling it
            if let recordedString = dependencies.stringsRepository.recordedString(formatted: formattedString) {
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
        dependencies.stringExtractor.formattedString(
            localizedStringKey: localizedStringKey,
            tableName: tableName,
            bundle: bundle,
            comment: comment
        )
    }
}
