// UserLinguaClient.swift

import CombineFeedback
import Dependencies
import Models
import RootFeature
import SwiftUI
import UIKit
import Utilities

public typealias UserLinguaConfiguration = Models.UserLinguaConfiguration

public final class UserLinguaClient {
    public static let shared = UserLinguaClient()
    private let dependencies: AllDependencies
    public private(set) var configuration = UserLinguaConfiguration()

    private lazy var store = RootFeature.store(
        initialState: .disabled,
        dependencies: .init(from: dependencies)
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
                .environmentObject(ViewDependency(configuration))
                .environmentObject(dependencies.deviceOrientationObservable.started())
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

    public var automaticallyOptInTextViews: Bool {
        configuration.automaticallyOptInTextViews
    }

    public var isEnabled: Bool {
        store.state != .disabled
    }

    public var isRecording: Bool {
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

    public func show() {
        store.send(.show)
    }

    public func configure(_ configuration: UserLinguaConfiguration) {
        self.configuration = configuration
    }

    public func record(
        localizedStringKey: LocalizedStringKey,
        tableName: String?,
        bundle: Bundle?,
        comment: String?
    ) {
        guard isRecording else { return }

        let formattedString = dependencies.stringExtractor.formattedString(
            localizedStringKey: localizedStringKey,
            tableName: tableName,
            bundle: bundle,
            comment: comment
        )

        dependencies.stringsRepository.record(formatted: formattedString)
    }

    public func record(
        value: String,
        key: String,
        bundle: Bundle?,
        tableName: String?,
        comment: String?
    ) {
        guard isRecording else { return }

        let localizedString = LocalizedString(
            value: value,
            localization: Localization(
                key: key,
                bundle: bundle,
                tableName: tableName,
                comment: comment
            )
        )

        dependencies.stringsRepository.record(localized: localizedString)
    }

    public func record(
        value: String,
        keyAndValue: String.LocalizationValue,
        bundle: Bundle?,
        tableName: String?,
        comment: String?
    ) {
        guard let key = keyAndValue.key else { return }

        record(
            value: value,
            key: key,
            bundle: bundle,
            tableName: tableName,
            comment: comment
        )
    }

    public func record(localizedStringResource: LocalizedStringResource) {
        guard isRecording else { return }
        let formattedString = FormattedString(localizedStringResource)
        dependencies.stringsRepository.record(formatted: formattedString)
    }

    public func record(string: String) {
        guard isRecording else { return }
        dependencies.stringsRepository.record(string: string)
    }

    public func record(
        value: String,
        format: String,
        arguments: [CVarArg]
    ) {
        guard isRecording else { return }

        let formattedString = FormattedString(
            value: value,
            format: .init(format),
            arguments: arguments.map { .cVarArg($0) }
        )
        dependencies.stringsRepository.record(formatted: formattedString)
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

    public func processString(_ string: String) -> String {
        if isRecording {
            dependencies.stringsRepository.record(string: string)
        }

        return displayString(for: FormattedString(string))
    }

    public func displayString(
        localizedStringKey: LocalizedStringKey,
        tableName: String?,
        bundle: Bundle?,
        comment: String?
    ) -> String {
        let formattedString = dependencies.stringExtractor.formattedString(
            localizedStringKey: localizedStringKey,
            tableName: tableName,
            bundle: bundle,
            comment: comment
        )

        return displayString(for: formattedString)
    }

    public func displayString(localizedStringResource: LocalizedStringResource) -> String {
        let formattedString = FormattedString(localizedStringResource)
        return displayString(for: formattedString)
    }

    private func displayString(for formattedString: FormattedString) -> String {
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
}
