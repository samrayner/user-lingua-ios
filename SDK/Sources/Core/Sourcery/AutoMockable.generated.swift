// AutoMockable.generated.swift

// Generated using Sourcery — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// swiftlint:disable line_length
// swiftlint:disable variable_name

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

import Combine
import SwiftUI

package class ContentSizeCategoryServiceProtocolMock: ContentSizeCategoryServiceProtocol {
    package var systemContentSizeCategory: UIContentSizeCategory {
        get { underlyingSystemContentSizeCategory }
        set(value) { underlyingSystemContentSizeCategory = value }
    }

    package var underlyingSystemContentSizeCategory: UIContentSizeCategory!
    package var appContentSizeCategory: UIContentSizeCategory {
        get { underlyingAppContentSizeCategory }
        set(value) { underlyingAppContentSizeCategory = value }
    }

    package var underlyingAppContentSizeCategory: UIContentSizeCategory!

    // MARK: - incrementAppContentSizeCategory

    package var incrementAppContentSizeCategoryVoidCallsCount = 0
    package var incrementAppContentSizeCategoryVoidCalled: Bool {
        incrementAppContentSizeCategoryVoidCallsCount > 0
    }

    package var incrementAppContentSizeCategoryVoidClosure: (() -> Void)?

    package func incrementAppContentSizeCategory() {
        incrementAppContentSizeCategoryVoidCallsCount += 1
        incrementAppContentSizeCategoryVoidClosure?()
    }

    // MARK: - decrementAppContentSizeCategory

    package var decrementAppContentSizeCategoryVoidCallsCount = 0
    package var decrementAppContentSizeCategoryVoidCalled: Bool {
        decrementAppContentSizeCategoryVoidCallsCount > 0
    }

    package var decrementAppContentSizeCategoryVoidClosure: (() -> Void)?

    package func decrementAppContentSizeCategory() {
        decrementAppContentSizeCategoryVoidCallsCount += 1
        decrementAppContentSizeCategoryVoidClosure?()
    }

    // MARK: - resetAppContentSizeCategory

    package var resetAppContentSizeCategoryVoidCallsCount = 0
    package var resetAppContentSizeCategoryVoidCalled: Bool {
        resetAppContentSizeCategoryVoidCallsCount > 0
    }

    package var resetAppContentSizeCategoryVoidClosure: (() -> Void)?

    package func resetAppContentSizeCategory() {
        resetAppContentSizeCategoryVoidCallsCount += 1
        resetAppContentSizeCategoryVoidClosure?()
    }
}

package class NotificationServiceProtocolMock: NotificationServiceProtocol {
    // MARK: - observe

    package var observeNameNotificationNameAsyncStreamNotificationCallsCount = 0
    package var observeNameNotificationNameAsyncStreamNotificationCalled: Bool {
        observeNameNotificationNameAsyncStreamNotificationCallsCount > 0
    }

    package var observeNameNotificationNameAsyncStreamNotificationReceivedName: (Notification.Name)?
    package var observeNameNotificationNameAsyncStreamNotificationReceivedInvocations: [Notification.Name] = []
    package var observeNameNotificationNameAsyncStreamNotificationReturnValue: AsyncStream<Notification>!
    package var observeNameNotificationNameAsyncStreamNotificationClosure: ((Notification.Name) async -> AsyncStream<Notification>)?

    package func observe(name: Notification.Name) async -> AsyncStream<Notification> {
        observeNameNotificationNameAsyncStreamNotificationCallsCount += 1
        observeNameNotificationNameAsyncStreamNotificationReceivedName = name
        observeNameNotificationNameAsyncStreamNotificationReceivedInvocations.append(name)
        if let observeNameNotificationNameAsyncStreamNotificationClosure {
            return await observeNameNotificationNameAsyncStreamNotificationClosure(name)
        } else {
            return observeNameNotificationNameAsyncStreamNotificationReturnValue
        }
    }

    // MARK: - observe

    package var observeNamesNotificationNameAsyncStreamNotificationCallsCount = 0
    package var observeNamesNotificationNameAsyncStreamNotificationCalled: Bool {
        observeNamesNotificationNameAsyncStreamNotificationCallsCount > 0
    }

    package var observeNamesNotificationNameAsyncStreamNotificationReceivedNames: [Notification.Name]?
    package var observeNamesNotificationNameAsyncStreamNotificationReceivedInvocations: [[Notification.Name]] = []
    package var observeNamesNotificationNameAsyncStreamNotificationReturnValue: AsyncStream<Notification>!
    package var observeNamesNotificationNameAsyncStreamNotificationClosure: (([Notification.Name]) async -> AsyncStream<Notification>)?

    package func observe(names: [Notification.Name]) async -> AsyncStream<Notification> {
        observeNamesNotificationNameAsyncStreamNotificationCallsCount += 1
        observeNamesNotificationNameAsyncStreamNotificationReceivedNames = names
        observeNamesNotificationNameAsyncStreamNotificationReceivedInvocations.append(names)
        if let observeNamesNotificationNameAsyncStreamNotificationClosure {
            return await observeNamesNotificationNameAsyncStreamNotificationClosure(names)
        } else {
            return observeNamesNotificationNameAsyncStreamNotificationReturnValue
        }
    }
}

package class OrientationServiceProtocolMock: OrientationServiceProtocol {
    // MARK: - orientationDidChange

    package var orientationDidChangeAsyncStreamUIDeviceOrientationCallsCount = 0
    package var orientationDidChangeAsyncStreamUIDeviceOrientationCalled: Bool {
        orientationDidChangeAsyncStreamUIDeviceOrientationCallsCount > 0
    }

    package var orientationDidChangeAsyncStreamUIDeviceOrientationReturnValue: AsyncStream<UIDeviceOrientation>!
    package var orientationDidChangeAsyncStreamUIDeviceOrientationClosure: (() async -> AsyncStream<UIDeviceOrientation>)?

    package func orientationDidChange() async -> AsyncStream<UIDeviceOrientation> {
        orientationDidChangeAsyncStreamUIDeviceOrientationCallsCount += 1
        if let orientationDidChangeAsyncStreamUIDeviceOrientationClosure {
            return await orientationDidChangeAsyncStreamUIDeviceOrientationClosure()
        } else {
            return orientationDidChangeAsyncStreamUIDeviceOrientationReturnValue
        }
    }
}

package class StringExtractorProtocolMock: StringExtractorProtocol {
    // MARK: - formattedString

    package var formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringCallsCount = 0
    package var formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringCalled: Bool {
        formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringCallsCount > 0
    }

    package var formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringReceivedArguments: (
        localizedStringKey: LocalizedStringKey,
        tableName: String?,
        bundle: Bundle?,
        comment: String?
    )?
    package var formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringReceivedInvocations: [
        (
            localizedStringKey: LocalizedStringKey,
            tableName: String?,
            bundle: Bundle?,
            comment: String?
        )
    ] = []
    package var formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringReturnValue: FormattedString!
    package var formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringClosure: ((
        LocalizedStringKey,
        String?,
        Bundle?,
        String?
    ) -> FormattedString)?

    package func formattedString(
        localizedStringKey: LocalizedStringKey,
        tableName: String?,
        bundle: Bundle?,
        comment: String?
    ) -> FormattedString {
        formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringCallsCount += 1
        formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringReceivedArguments = (
            localizedStringKey: localizedStringKey,
            tableName: tableName,
            bundle: bundle,
            comment: comment
        )
        formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringReceivedInvocations
            .append((
                localizedStringKey: localizedStringKey,
                tableName: tableName,
                bundle: bundle,
                comment: comment
            ))
        if let formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringClosure {
            return formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringClosure(
                localizedStringKey,
                tableName,
                bundle,
                comment
            )
        } else {
            return formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringReturnValue
        }
    }
}

package class StringsRepositoryProtocolMock: StringsRepositoryProtocol {
    // MARK: - record

    package var recordFormattedFormattedStringVoidCallsCount = 0
    package var recordFormattedFormattedStringVoidCalled: Bool {
        recordFormattedFormattedStringVoidCallsCount > 0
    }

    package var recordFormattedFormattedStringVoidReceivedFormatted: FormattedString?
    package var recordFormattedFormattedStringVoidReceivedInvocations: [FormattedString] = []
    package var recordFormattedFormattedStringVoidClosure: ((FormattedString) -> Void)?

    package func record(formatted: FormattedString) {
        recordFormattedFormattedStringVoidCallsCount += 1
        recordFormattedFormattedStringVoidReceivedFormatted = formatted
        recordFormattedFormattedStringVoidReceivedInvocations.append(formatted)
        recordFormattedFormattedStringVoidClosure?(formatted)
    }

    // MARK: - record

    package var recordLocalizedLocalizedStringVoidCallsCount = 0
    package var recordLocalizedLocalizedStringVoidCalled: Bool {
        recordLocalizedLocalizedStringVoidCallsCount > 0
    }

    package var recordLocalizedLocalizedStringVoidReceivedLocalized: LocalizedString?
    package var recordLocalizedLocalizedStringVoidReceivedInvocations: [LocalizedString] = []
    package var recordLocalizedLocalizedStringVoidClosure: ((LocalizedString) -> Void)?

    package func record(localized: LocalizedString) {
        recordLocalizedLocalizedStringVoidCallsCount += 1
        recordLocalizedLocalizedStringVoidReceivedLocalized = localized
        recordLocalizedLocalizedStringVoidReceivedInvocations.append(localized)
        recordLocalizedLocalizedStringVoidClosure?(localized)
    }

    // MARK: - record

    package var recordStringStringVoidCallsCount = 0
    package var recordStringStringVoidCalled: Bool {
        recordStringStringVoidCallsCount > 0
    }

    package var recordStringStringVoidReceivedString: String?
    package var recordStringStringVoidReceivedInvocations: [String] = []
    package var recordStringStringVoidClosure: ((String) -> Void)?

    package func record(string: String) {
        recordStringStringVoidCallsCount += 1
        recordStringStringVoidReceivedString = string
        recordStringStringVoidReceivedInvocations.append(string)
        recordStringStringVoidClosure?(string)
    }

    // MARK: - recordedStrings

    package var recordedStringsRecordedStringCallsCount = 0
    package var recordedStringsRecordedStringCalled: Bool {
        recordedStringsRecordedStringCallsCount > 0
    }

    package var recordedStringsRecordedStringReturnValue: [RecordedString]!
    package var recordedStringsRecordedStringClosure: (() -> [RecordedString])?

    package func recordedStrings() -> [RecordedString] {
        recordedStringsRecordedStringCallsCount += 1
        if let recordedStringsRecordedStringClosure {
            return recordedStringsRecordedStringClosure()
        } else {
            return recordedStringsRecordedStringReturnValue
        }
    }

    // MARK: - recordedString

    package var recordedStringFormattedFormattedStringRecordedStringCallsCount = 0
    package var recordedStringFormattedFormattedStringRecordedStringCalled: Bool {
        recordedStringFormattedFormattedStringRecordedStringCallsCount > 0
    }

    package var recordedStringFormattedFormattedStringRecordedStringReceivedFormatted: FormattedString?
    package var recordedStringFormattedFormattedStringRecordedStringReceivedInvocations: [FormattedString] = []
    package var recordedStringFormattedFormattedStringRecordedStringReturnValue: RecordedString?
    package var recordedStringFormattedFormattedStringRecordedStringClosure: ((FormattedString) -> RecordedString?)?

    package func recordedString(formatted: FormattedString) -> RecordedString? {
        recordedStringFormattedFormattedStringRecordedStringCallsCount += 1
        recordedStringFormattedFormattedStringRecordedStringReceivedFormatted = formatted
        recordedStringFormattedFormattedStringRecordedStringReceivedInvocations.append(formatted)
        if let recordedStringFormattedFormattedStringRecordedStringClosure {
            return recordedStringFormattedFormattedStringRecordedStringClosure(formatted)
        } else {
            return recordedStringFormattedFormattedStringRecordedStringReturnValue
        }
    }

    // MARK: - recordedString

    package var recordedStringLocalizedLocalizedStringRecordedStringCallsCount = 0
    package var recordedStringLocalizedLocalizedStringRecordedStringCalled: Bool {
        recordedStringLocalizedLocalizedStringRecordedStringCallsCount > 0
    }

    package var recordedStringLocalizedLocalizedStringRecordedStringReceivedLocalized: LocalizedString?
    package var recordedStringLocalizedLocalizedStringRecordedStringReceivedInvocations: [LocalizedString] = []
    package var recordedStringLocalizedLocalizedStringRecordedStringReturnValue: RecordedString?
    package var recordedStringLocalizedLocalizedStringRecordedStringClosure: ((LocalizedString) -> RecordedString?)?

    package func recordedString(localized: LocalizedString) -> RecordedString? {
        recordedStringLocalizedLocalizedStringRecordedStringCallsCount += 1
        recordedStringLocalizedLocalizedStringRecordedStringReceivedLocalized = localized
        recordedStringLocalizedLocalizedStringRecordedStringReceivedInvocations.append(localized)
        if let recordedStringLocalizedLocalizedStringRecordedStringClosure {
            return recordedStringLocalizedLocalizedStringRecordedStringClosure(localized)
        } else {
            return recordedStringLocalizedLocalizedStringRecordedStringReturnValue
        }
    }

    // MARK: - recordedString

    package var recordedStringStringStringRecordedStringCallsCount = 0
    package var recordedStringStringStringRecordedStringCalled: Bool {
        recordedStringStringStringRecordedStringCallsCount > 0
    }

    package var recordedStringStringStringRecordedStringReceivedString: String?
    package var recordedStringStringStringRecordedStringReceivedInvocations: [String] = []
    package var recordedStringStringStringRecordedStringReturnValue: RecordedString?
    package var recordedStringStringStringRecordedStringClosure: ((String) -> RecordedString?)?

    package func recordedString(string: String) -> RecordedString? {
        recordedStringStringStringRecordedStringCallsCount += 1
        recordedStringStringStringRecordedStringReceivedString = string
        recordedStringStringStringRecordedStringReceivedInvocations.append(string)
        if let recordedStringStringStringRecordedStringClosure {
            return recordedStringStringStringRecordedStringClosure(string)
        } else {
            return recordedStringStringStringRecordedStringReturnValue
        }
    }
}

package class SuggestionsRepositoryProtocolMock: SuggestionsRepositoryProtocol {
    // MARK: - saveSuggestion

    package var saveSuggestionSuggestionSuggestionVoidCallsCount = 0
    package var saveSuggestionSuggestionSuggestionVoidCalled: Bool {
        saveSuggestionSuggestionSuggestionVoidCallsCount > 0
    }

    package var saveSuggestionSuggestionSuggestionVoidReceivedSuggestion: Suggestion?
    package var saveSuggestionSuggestionSuggestionVoidReceivedInvocations: [Suggestion] = []
    package var saveSuggestionSuggestionSuggestionVoidClosure: ((Suggestion) -> Void)?

    package func saveSuggestion(_ suggestion: Suggestion) {
        saveSuggestionSuggestionSuggestionVoidCallsCount += 1
        saveSuggestionSuggestionSuggestionVoidReceivedSuggestion = suggestion
        saveSuggestionSuggestionSuggestionVoidReceivedInvocations.append(suggestion)
        saveSuggestionSuggestionSuggestionVoidClosure?(suggestion)
    }

    // MARK: - suggestion

    package var suggestionForOriginalStringLocaleLocaleSuggestionCallsCount = 0
    package var suggestionForOriginalStringLocaleLocaleSuggestionCalled: Bool {
        suggestionForOriginalStringLocaleLocaleSuggestionCallsCount > 0
    }

    package var suggestionForOriginalStringLocaleLocaleSuggestionReceivedArguments: (original: String, locale: Locale)?
    package var suggestionForOriginalStringLocaleLocaleSuggestionReceivedInvocations: [(original: String, locale: Locale)] = []
    package var suggestionForOriginalStringLocaleLocaleSuggestionReturnValue: Suggestion?
    package var suggestionForOriginalStringLocaleLocaleSuggestionClosure: ((String, Locale) -> Suggestion?)?

    package func suggestion(for original: String, locale: Locale) -> Suggestion? {
        suggestionForOriginalStringLocaleLocaleSuggestionCallsCount += 1
        suggestionForOriginalStringLocaleLocaleSuggestionReceivedArguments = (original: original, locale: locale)
        suggestionForOriginalStringLocaleLocaleSuggestionReceivedInvocations.append((original: original, locale: locale))
        if let suggestionForOriginalStringLocaleLocaleSuggestionClosure {
            return suggestionForOriginalStringLocaleLocaleSuggestionClosure(original, locale)
        } else {
            return suggestionForOriginalStringLocaleLocaleSuggestionReturnValue
        }
    }
}

package class UserLinguaObservableProtocolMock: UserLinguaObservableProtocol {
    package var refreshPublisher: AnyPublisher<Void, Never> {
        get { underlyingRefreshPublisher }
        set(value) { underlyingRefreshPublisher = value }
    }

    package var underlyingRefreshPublisher: AnyPublisher<Void, Never>!

    // MARK: - refresh

    package var refreshVoidCallsCount = 0
    package var refreshVoidCalled: Bool {
        refreshVoidCallsCount > 0
    }

    package var refreshVoidClosure: (() -> Void)?

    package func refresh() {
        refreshVoidCallsCount += 1
        refreshVoidClosure?()
    }
}

package class WindowServiceProtocolMock: WindowServiceProtocol {
    package var userLinguaWindow: UIWindow {
        get { underlyingUserLinguaWindow }
        set(value) { underlyingUserLinguaWindow = value }
    }

    package var underlyingUserLinguaWindow: UIWindow!
    package var appUIStyle: UIUserInterfaceStyle {
        get { underlyingAppUIStyle }
        set(value) { underlyingAppUIStyle = value }
    }

    package var underlyingAppUIStyle: UIUserInterfaceStyle!
    package var appYOffset: CGFloat {
        get { underlyingAppYOffset }
        set(value) { underlyingAppYOffset = value }
    }

    package var underlyingAppYOffset: CGFloat!

    // MARK: - setRootView

    package var setRootViewSomeViewVoidCallsCount = 0
    package var setRootViewSomeViewVoidCalled: Bool {
        setRootViewSomeViewVoidCallsCount > 0
    }

    package var setRootViewSomeViewVoidReceived: (any View)?
    package var setRootViewSomeViewVoidReceivedInvocations: [any View] = []
    package var setRootViewSomeViewVoidClosure: ((any View) -> Void)?

    package func setRootView(_ arg0: some View) {
        setRootViewSomeViewVoidCallsCount += 1
        setRootViewSomeViewVoidReceived = arg0
        setRootViewSomeViewVoidReceivedInvocations.append(arg0)
        setRootViewSomeViewVoidClosure?(arg0)
    }

    // MARK: - screenshotAppWindow

    package var screenshotAppWindowUIImageCallsCount = 0
    package var screenshotAppWindowUIImageCalled: Bool {
        screenshotAppWindowUIImageCallsCount > 0
    }

    package var screenshotAppWindowUIImageReturnValue: UIImage?
    package var screenshotAppWindowUIImageClosure: (() -> UIImage?)?

    package func screenshotAppWindow() -> UIImage? {
        screenshotAppWindowUIImageCallsCount += 1
        if let screenshotAppWindowUIImageClosure {
            return screenshotAppWindowUIImageClosure()
        } else {
            return screenshotAppWindowUIImageReturnValue
        }
    }

    // MARK: - showWindow

    package var showWindowVoidCallsCount = 0
    package var showWindowVoidCalled: Bool {
        showWindowVoidCallsCount > 0
    }

    package var showWindowVoidClosure: (() -> Void)?

    package func showWindow() {
        showWindowVoidCallsCount += 1
        showWindowVoidClosure?()
    }

    // MARK: - hideWindow

    package var hideWindowVoidCallsCount = 0
    package var hideWindowVoidCalled: Bool {
        hideWindowVoidCallsCount > 0
    }

    package var hideWindowVoidClosure: (() -> Void)?

    package func hideWindow() {
        hideWindowVoidCallsCount += 1
        hideWindowVoidClosure?()
    }

    // MARK: - toggleDarkMode

    package var toggleDarkModeVoidCallsCount = 0
    package var toggleDarkModeVoidCalled: Bool {
        toggleDarkModeVoidCallsCount > 0
    }

    package var toggleDarkModeVoidClosure: (() -> Void)?

    package func toggleDarkMode() {
        toggleDarkModeVoidCallsCount += 1
        toggleDarkModeVoidClosure?()
    }

    // MARK: - positionApp

    package var positionAppFocusingCGPointWithinCGRectAnimationDurationTimeIntervalVoidCallsCount = 0
    package var positionAppFocusingCGPointWithinCGRectAnimationDurationTimeIntervalVoidCalled: Bool {
        positionAppFocusingCGPointWithinCGRectAnimationDurationTimeIntervalVoidCallsCount > 0
    }

    package var positionAppFocusingCGPointWithinCGRectAnimationDurationTimeIntervalVoidReceivedArguments: (
        focusing: CGPoint,
        within: CGRect,
        animationDuration: TimeInterval
    )?
    package var positionAppFocusingCGPointWithinCGRectAnimationDurationTimeIntervalVoidReceivedInvocations: [(
        focusing: CGPoint,
        within: CGRect,
        animationDuration: TimeInterval
    )] = []
    package var positionAppFocusingCGPointWithinCGRectAnimationDurationTimeIntervalVoidClosure: ((CGPoint, CGRect, TimeInterval) -> Void)?

    package func positionApp(focusing: CGPoint, within: CGRect, animationDuration: TimeInterval) {
        positionAppFocusingCGPointWithinCGRectAnimationDurationTimeIntervalVoidCallsCount += 1
        positionAppFocusingCGPointWithinCGRectAnimationDurationTimeIntervalVoidReceivedArguments = (
            focusing: focusing,
            within: within,
            animationDuration: animationDuration
        )
        positionAppFocusingCGPointWithinCGRectAnimationDurationTimeIntervalVoidReceivedInvocations.append((
            focusing: focusing,
            within: within,
            animationDuration: animationDuration
        ))
        positionAppFocusingCGPointWithinCGRectAnimationDurationTimeIntervalVoidClosure?(focusing, within, animationDuration)
    }

    // MARK: - positionApp

    package var positionAppYOffsetCGFloatAnimationDurationTimeIntervalVoidCallsCount = 0
    package var positionAppYOffsetCGFloatAnimationDurationTimeIntervalVoidCalled: Bool {
        positionAppYOffsetCGFloatAnimationDurationTimeIntervalVoidCallsCount > 0
    }

    package var positionAppYOffsetCGFloatAnimationDurationTimeIntervalVoidReceivedArguments: (
        yOffset: CGFloat,
        animationDuration: TimeInterval
    )?
    package var positionAppYOffsetCGFloatAnimationDurationTimeIntervalVoidReceivedInvocations: [(
        yOffset: CGFloat,
        animationDuration: TimeInterval
    )] = []
    package var positionAppYOffsetCGFloatAnimationDurationTimeIntervalVoidClosure: ((CGFloat, TimeInterval) -> Void)?

    package func positionApp(yOffset: CGFloat, animationDuration: TimeInterval) {
        positionAppYOffsetCGFloatAnimationDurationTimeIntervalVoidCallsCount += 1
        positionAppYOffsetCGFloatAnimationDurationTimeIntervalVoidReceivedArguments = (
            yOffset: yOffset,
            animationDuration: animationDuration
        )
        positionAppYOffsetCGFloatAnimationDurationTimeIntervalVoidReceivedInvocations.append((
            yOffset: yOffset,
            animationDuration: animationDuration
        ))
        positionAppYOffsetCGFloatAnimationDurationTimeIntervalVoidClosure?(yOffset, animationDuration)
    }

    // MARK: - resetAppPosition

    package var resetAppPositionVoidCallsCount = 0
    package var resetAppPositionVoidCalled: Bool {
        resetAppPositionVoidCallsCount > 0
    }

    package var resetAppPositionVoidClosure: (() -> Void)?

    package func resetAppPosition() {
        resetAppPositionVoidCallsCount += 1
        resetAppPositionVoidClosure?()
    }

    // MARK: - resetAppWindow

    package var resetAppWindowVoidCallsCount = 0
    package var resetAppWindowVoidCalled: Bool {
        resetAppWindowVoidCallsCount > 0
    }

    package var resetAppWindowVoidClosure: (() -> Void)?

    package func resetAppWindow() {
        resetAppWindowVoidCallsCount += 1
        resetAppWindowVoidClosure?()
    }
}
