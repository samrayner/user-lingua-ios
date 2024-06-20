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























public class ConfigurationProtocolMock: ConfigurationProtocol {

    public init() {}

    public var automaticallyOptInTextViews: Bool {
        get { return underlyingAutomaticallyOptInTextViews }
        set(value) { underlyingAutomaticallyOptInTextViews = value }
    }
    public var underlyingAutomaticallyOptInTextViews: (Bool)!
    public var appSupportsDynamicType: Bool {
        get { return underlyingAppSupportsDynamicType }
        set(value) { underlyingAppSupportsDynamicType = value }
    }
    public var underlyingAppSupportsDynamicType: (Bool)!
    public var appSupportsDarkMode: Bool {
        get { return underlyingAppSupportsDarkMode }
        set(value) { underlyingAppSupportsDarkMode = value }
    }
    public var underlyingAppSupportsDarkMode: (Bool)!
    public var baseLocale: Locale {
        get { return underlyingBaseLocale }
        set(value) { underlyingBaseLocale = value }
    }
    public var underlyingBaseLocale: (Locale)!



}
package class ContentSizeCategoryServiceProtocolMock: ContentSizeCategoryServiceProtocol {


    package var systemContentSizeCategory: UIContentSizeCategory {
        get { return underlyingSystemContentSizeCategory }
        set(value) { underlyingSystemContentSizeCategory = value }
    }
    package var underlyingSystemContentSizeCategory: (UIContentSizeCategory)!
    package var appContentSizeCategory: UIContentSizeCategory {
        get { return underlyingAppContentSizeCategory }
        set(value) { underlyingAppContentSizeCategory = value }
    }
    package var underlyingAppContentSizeCategory: (UIContentSizeCategory)!


    //MARK: - incrementAppContentSizeCategory

    package var incrementAppContentSizeCategoryVoidCallsCount = 0
    package var incrementAppContentSizeCategoryVoidCalled: Bool {
        return incrementAppContentSizeCategoryVoidCallsCount > 0
    }
    package var incrementAppContentSizeCategoryVoidClosure: (() -> Void)?

    package func incrementAppContentSizeCategory() {
        incrementAppContentSizeCategoryVoidCallsCount += 1
        incrementAppContentSizeCategoryVoidClosure?()
    }

    //MARK: - decrementAppContentSizeCategory

    package var decrementAppContentSizeCategoryVoidCallsCount = 0
    package var decrementAppContentSizeCategoryVoidCalled: Bool {
        return decrementAppContentSizeCategoryVoidCallsCount > 0
    }
    package var decrementAppContentSizeCategoryVoidClosure: (() -> Void)?

    package func decrementAppContentSizeCategory() {
        decrementAppContentSizeCategoryVoidCallsCount += 1
        decrementAppContentSizeCategoryVoidClosure?()
    }

    //MARK: - resetAppContentSizeCategory

    package var resetAppContentSizeCategoryVoidCallsCount = 0
    package var resetAppContentSizeCategoryVoidCalled: Bool {
        return resetAppContentSizeCategoryVoidCallsCount > 0
    }
    package var resetAppContentSizeCategoryVoidClosure: (() -> Void)?

    package func resetAppContentSizeCategory() {
        resetAppContentSizeCategoryVoidCallsCount += 1
        resetAppContentSizeCategoryVoidClosure?()
    }


}
package class OrientationServiceProtocolMock: OrientationServiceProtocol {




    //MARK: - orientationDidChange

    package var orientationDidChangeAnyPublisherUIDeviceOrientationNeverCallsCount = 0
    package var orientationDidChangeAnyPublisherUIDeviceOrientationNeverCalled: Bool {
        return orientationDidChangeAnyPublisherUIDeviceOrientationNeverCallsCount > 0
    }
    package var orientationDidChangeAnyPublisherUIDeviceOrientationNeverReturnValue: AnyPublisher<UIDeviceOrientation, Never>!
    package var orientationDidChangeAnyPublisherUIDeviceOrientationNeverClosure: (() -> AnyPublisher<UIDeviceOrientation, Never>)?

    package func orientationDidChange() -> AnyPublisher<UIDeviceOrientation, Never> {
        orientationDidChangeAnyPublisherUIDeviceOrientationNeverCallsCount += 1
        if let orientationDidChangeAnyPublisherUIDeviceOrientationNeverClosure = orientationDidChangeAnyPublisherUIDeviceOrientationNeverClosure {
            return orientationDidChangeAnyPublisherUIDeviceOrientationNeverClosure()
        } else {
            return orientationDidChangeAnyPublisherUIDeviceOrientationNeverReturnValue
        }
    }


}
package class StringExtractorProtocolMock: StringExtractorProtocol {




    //MARK: - formattedString

    package var formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringCallsCount = 0
    package var formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringCalled: Bool {
        return formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringCallsCount > 0
    }
    package var formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringReceivedArguments: (localizedStringKey: LocalizedStringKey, tableName: String?, bundle: Bundle?, comment: String?)?
    package var formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringReceivedInvocations: [(localizedStringKey: LocalizedStringKey, tableName: String?, bundle: Bundle?, comment: String?)] = []
    package var formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringReturnValue: FormattedString!
    package var formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringClosure: ((LocalizedStringKey, String?, Bundle?, String?) -> FormattedString)?

    package func formattedString(localizedStringKey: LocalizedStringKey, tableName: String?, bundle: Bundle?, comment: String?) -> FormattedString {
        formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringCallsCount += 1
        formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringReceivedArguments = (localizedStringKey: localizedStringKey, tableName: tableName, bundle: bundle, comment: comment)
        formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringReceivedInvocations.append((localizedStringKey: localizedStringKey, tableName: tableName, bundle: bundle, comment: comment))
        if let formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringClosure = formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringClosure {
            return formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringClosure(localizedStringKey, tableName, bundle, comment)
        } else {
            return formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringReturnValue
        }
    }


}
package class StringsRepositoryProtocolMock: StringsRepositoryProtocol {




    //MARK: - record

    package var recordFormattedFormattedStringVoidCallsCount = 0
    package var recordFormattedFormattedStringVoidCalled: Bool {
        return recordFormattedFormattedStringVoidCallsCount > 0
    }
    package var recordFormattedFormattedStringVoidReceivedFormatted: (FormattedString)?
    package var recordFormattedFormattedStringVoidReceivedInvocations: [(FormattedString)] = []
    package var recordFormattedFormattedStringVoidClosure: ((FormattedString) -> Void)?

    package func record(formatted: FormattedString) {
        recordFormattedFormattedStringVoidCallsCount += 1
        recordFormattedFormattedStringVoidReceivedFormatted = formatted
        recordFormattedFormattedStringVoidReceivedInvocations.append(formatted)
        recordFormattedFormattedStringVoidClosure?(formatted)
    }

    //MARK: - record

    package var recordLocalizedLocalizedStringVoidCallsCount = 0
    package var recordLocalizedLocalizedStringVoidCalled: Bool {
        return recordLocalizedLocalizedStringVoidCallsCount > 0
    }
    package var recordLocalizedLocalizedStringVoidReceivedLocalized: (LocalizedString)?
    package var recordLocalizedLocalizedStringVoidReceivedInvocations: [(LocalizedString)] = []
    package var recordLocalizedLocalizedStringVoidClosure: ((LocalizedString) -> Void)?

    package func record(localized: LocalizedString) {
        recordLocalizedLocalizedStringVoidCallsCount += 1
        recordLocalizedLocalizedStringVoidReceivedLocalized = localized
        recordLocalizedLocalizedStringVoidReceivedInvocations.append(localized)
        recordLocalizedLocalizedStringVoidClosure?(localized)
    }

    //MARK: - record

    package var recordStringStringVoidCallsCount = 0
    package var recordStringStringVoidCalled: Bool {
        return recordStringStringVoidCallsCount > 0
    }
    package var recordStringStringVoidReceivedString: (String)?
    package var recordStringStringVoidReceivedInvocations: [(String)] = []
    package var recordStringStringVoidClosure: ((String) -> Void)?

    package func record(string: String) {
        recordStringStringVoidCallsCount += 1
        recordStringStringVoidReceivedString = string
        recordStringStringVoidReceivedInvocations.append(string)
        recordStringStringVoidClosure?(string)
    }

    //MARK: - recordedStrings

    package var recordedStringsRecordedStringCallsCount = 0
    package var recordedStringsRecordedStringCalled: Bool {
        return recordedStringsRecordedStringCallsCount > 0
    }
    package var recordedStringsRecordedStringReturnValue: [RecordedString]!
    package var recordedStringsRecordedStringClosure: (() -> [RecordedString])?

    package func recordedStrings() -> [RecordedString] {
        recordedStringsRecordedStringCallsCount += 1
        if let recordedStringsRecordedStringClosure = recordedStringsRecordedStringClosure {
            return recordedStringsRecordedStringClosure()
        } else {
            return recordedStringsRecordedStringReturnValue
        }
    }

    //MARK: - recordedString

    package var recordedStringFormattedFormattedStringRecordedStringCallsCount = 0
    package var recordedStringFormattedFormattedStringRecordedStringCalled: Bool {
        return recordedStringFormattedFormattedStringRecordedStringCallsCount > 0
    }
    package var recordedStringFormattedFormattedStringRecordedStringReceivedFormatted: (FormattedString)?
    package var recordedStringFormattedFormattedStringRecordedStringReceivedInvocations: [(FormattedString)] = []
    package var recordedStringFormattedFormattedStringRecordedStringReturnValue: RecordedString?
    package var recordedStringFormattedFormattedStringRecordedStringClosure: ((FormattedString) -> RecordedString?)?

    package func recordedString(formatted: FormattedString) -> RecordedString? {
        recordedStringFormattedFormattedStringRecordedStringCallsCount += 1
        recordedStringFormattedFormattedStringRecordedStringReceivedFormatted = formatted
        recordedStringFormattedFormattedStringRecordedStringReceivedInvocations.append(formatted)
        if let recordedStringFormattedFormattedStringRecordedStringClosure = recordedStringFormattedFormattedStringRecordedStringClosure {
            return recordedStringFormattedFormattedStringRecordedStringClosure(formatted)
        } else {
            return recordedStringFormattedFormattedStringRecordedStringReturnValue
        }
    }

    //MARK: - recordedString

    package var recordedStringLocalizedLocalizedStringRecordedStringCallsCount = 0
    package var recordedStringLocalizedLocalizedStringRecordedStringCalled: Bool {
        return recordedStringLocalizedLocalizedStringRecordedStringCallsCount > 0
    }
    package var recordedStringLocalizedLocalizedStringRecordedStringReceivedLocalized: (LocalizedString)?
    package var recordedStringLocalizedLocalizedStringRecordedStringReceivedInvocations: [(LocalizedString)] = []
    package var recordedStringLocalizedLocalizedStringRecordedStringReturnValue: RecordedString?
    package var recordedStringLocalizedLocalizedStringRecordedStringClosure: ((LocalizedString) -> RecordedString?)?

    package func recordedString(localized: LocalizedString) -> RecordedString? {
        recordedStringLocalizedLocalizedStringRecordedStringCallsCount += 1
        recordedStringLocalizedLocalizedStringRecordedStringReceivedLocalized = localized
        recordedStringLocalizedLocalizedStringRecordedStringReceivedInvocations.append(localized)
        if let recordedStringLocalizedLocalizedStringRecordedStringClosure = recordedStringLocalizedLocalizedStringRecordedStringClosure {
            return recordedStringLocalizedLocalizedStringRecordedStringClosure(localized)
        } else {
            return recordedStringLocalizedLocalizedStringRecordedStringReturnValue
        }
    }

    //MARK: - recordedString

    package var recordedStringStringStringRecordedStringCallsCount = 0
    package var recordedStringStringStringRecordedStringCalled: Bool {
        return recordedStringStringStringRecordedStringCallsCount > 0
    }
    package var recordedStringStringStringRecordedStringReceivedString: (String)?
    package var recordedStringStringStringRecordedStringReceivedInvocations: [(String)] = []
    package var recordedStringStringStringRecordedStringReturnValue: RecordedString?
    package var recordedStringStringStringRecordedStringClosure: ((String) -> RecordedString?)?

    package func recordedString(string: String) -> RecordedString? {
        recordedStringStringStringRecordedStringCallsCount += 1
        recordedStringStringStringRecordedStringReceivedString = string
        recordedStringStringStringRecordedStringReceivedInvocations.append(string)
        if let recordedStringStringStringRecordedStringClosure = recordedStringStringStringRecordedStringClosure {
            return recordedStringStringStringRecordedStringClosure(string)
        } else {
            return recordedStringStringStringRecordedStringReturnValue
        }
    }


}
package class SuggestionsRepositoryProtocolMock: SuggestionsRepositoryProtocol {




    //MARK: - saveSuggestion

    package var saveSuggestionSuggestionSuggestionVoidCallsCount = 0
    package var saveSuggestionSuggestionSuggestionVoidCalled: Bool {
        return saveSuggestionSuggestionSuggestionVoidCallsCount > 0
    }
    package var saveSuggestionSuggestionSuggestionVoidReceivedSuggestion: (Suggestion)?
    package var saveSuggestionSuggestionSuggestionVoidReceivedInvocations: [(Suggestion)] = []
    package var saveSuggestionSuggestionSuggestionVoidClosure: ((Suggestion) -> Void)?

    package func saveSuggestion(_ suggestion: Suggestion) {
        saveSuggestionSuggestionSuggestionVoidCallsCount += 1
        saveSuggestionSuggestionSuggestionVoidReceivedSuggestion = suggestion
        saveSuggestionSuggestionSuggestionVoidReceivedInvocations.append(suggestion)
        saveSuggestionSuggestionSuggestionVoidClosure?(suggestion)
    }

    //MARK: - suggestion

    package var suggestionForOriginalStringLocaleLocaleSuggestionCallsCount = 0
    package var suggestionForOriginalStringLocaleLocaleSuggestionCalled: Bool {
        return suggestionForOriginalStringLocaleLocaleSuggestionCallsCount > 0
    }
    package var suggestionForOriginalStringLocaleLocaleSuggestionReceivedArguments: (original: String, locale: Locale)?
    package var suggestionForOriginalStringLocaleLocaleSuggestionReceivedInvocations: [(original: String, locale: Locale)] = []
    package var suggestionForOriginalStringLocaleLocaleSuggestionReturnValue: Suggestion?
    package var suggestionForOriginalStringLocaleLocaleSuggestionClosure: ((String, Locale) -> Suggestion?)?

    package func suggestion(for original: String, locale: Locale) -> Suggestion? {
        suggestionForOriginalStringLocaleLocaleSuggestionCallsCount += 1
        suggestionForOriginalStringLocaleLocaleSuggestionReceivedArguments = (original: original, locale: locale)
        suggestionForOriginalStringLocaleLocaleSuggestionReceivedInvocations.append((original: original, locale: locale))
        if let suggestionForOriginalStringLocaleLocaleSuggestionClosure = suggestionForOriginalStringLocaleLocaleSuggestionClosure {
            return suggestionForOriginalStringLocaleLocaleSuggestionClosure(original, locale)
        } else {
            return suggestionForOriginalStringLocaleLocaleSuggestionReturnValue
        }
    }


}
package class UserLinguaObservableProtocolMock: UserLinguaObservableProtocol {


    package var refreshPublisher: AnyPublisher<Void, Never> {
        get { return underlyingRefreshPublisher }
        set(value) { underlyingRefreshPublisher = value }
    }
    package var underlyingRefreshPublisher: (AnyPublisher<Void, Never>)!


    //MARK: - refresh

    package var refreshVoidCallsCount = 0
    package var refreshVoidCalled: Bool {
        return refreshVoidCallsCount > 0
    }
    package var refreshVoidClosure: (() -> Void)?

    package func refresh() {
        refreshVoidCallsCount += 1
        refreshVoidClosure?()
    }


}
package class WindowServiceProtocolMock: WindowServiceProtocol {


    package var userLinguaWindow: UIWindow {
        get { return underlyingUserLinguaWindow }
        set(value) { underlyingUserLinguaWindow = value }
    }
    package var underlyingUserLinguaWindow: (UIWindow)!
    package var appUIStyle: UIUserInterfaceStyle {
        get { return underlyingAppUIStyle }
        set(value) { underlyingAppUIStyle = value }
    }
    package var underlyingAppUIStyle: (UIUserInterfaceStyle)!
    package var appYOffset: CGFloat {
        get { return underlyingAppYOffset }
        set(value) { underlyingAppYOffset = value }
    }
    package var underlyingAppYOffset: (CGFloat)!


    //MARK: - setRootView

    package var setRootViewSomeViewVoidCallsCount = 0
    package var setRootViewSomeViewVoidCalled: Bool {
        return setRootViewSomeViewVoidCallsCount > 0
    }
    package var setRootViewSomeViewVoidReceived: (any View)?
    package var setRootViewSomeViewVoidReceivedInvocations: [(any View)] = []
    package var setRootViewSomeViewVoidClosure: ((any View) -> Void)?

    package func setRootView(_ arg0: some View) {
        setRootViewSomeViewVoidCallsCount += 1
        setRootViewSomeViewVoidReceived = arg0
        setRootViewSomeViewVoidReceivedInvocations.append(arg0)
        setRootViewSomeViewVoidClosure?(arg0)
    }

    //MARK: - screenshotAppWindow

    package var screenshotAppWindowUIImageCallsCount = 0
    package var screenshotAppWindowUIImageCalled: Bool {
        return screenshotAppWindowUIImageCallsCount > 0
    }
    package var screenshotAppWindowUIImageReturnValue: UIImage?
    package var screenshotAppWindowUIImageClosure: (() -> UIImage?)?

    package func screenshotAppWindow() -> UIImage? {
        screenshotAppWindowUIImageCallsCount += 1
        if let screenshotAppWindowUIImageClosure = screenshotAppWindowUIImageClosure {
            return screenshotAppWindowUIImageClosure()
        } else {
            return screenshotAppWindowUIImageReturnValue
        }
    }

    //MARK: - showWindow

    package var showWindowVoidCallsCount = 0
    package var showWindowVoidCalled: Bool {
        return showWindowVoidCallsCount > 0
    }
    package var showWindowVoidClosure: (() -> Void)?

    package func showWindow() {
        showWindowVoidCallsCount += 1
        showWindowVoidClosure?()
    }

    //MARK: - hideWindow

    package var hideWindowVoidCallsCount = 0
    package var hideWindowVoidCalled: Bool {
        return hideWindowVoidCallsCount > 0
    }
    package var hideWindowVoidClosure: (() -> Void)?

    package func hideWindow() {
        hideWindowVoidCallsCount += 1
        hideWindowVoidClosure?()
    }

    //MARK: - toggleDarkMode

    package var toggleDarkModeVoidCallsCount = 0
    package var toggleDarkModeVoidCalled: Bool {
        return toggleDarkModeVoidCallsCount > 0
    }
    package var toggleDarkModeVoidClosure: (() -> Void)?

    package func toggleDarkMode() {
        toggleDarkModeVoidCallsCount += 1
        toggleDarkModeVoidClosure?()
    }

    //MARK: - positionApp

    package var positionAppFocusingCGPointWithinCGRectAnimationDurationTimeIntervalVoidCallsCount = 0
    package var positionAppFocusingCGPointWithinCGRectAnimationDurationTimeIntervalVoidCalled: Bool {
        return positionAppFocusingCGPointWithinCGRectAnimationDurationTimeIntervalVoidCallsCount > 0
    }
    package var positionAppFocusingCGPointWithinCGRectAnimationDurationTimeIntervalVoidReceivedArguments: (focusing: CGPoint, within: CGRect, animationDuration: TimeInterval)?
    package var positionAppFocusingCGPointWithinCGRectAnimationDurationTimeIntervalVoidReceivedInvocations: [(focusing: CGPoint, within: CGRect, animationDuration: TimeInterval)] = []
    package var positionAppFocusingCGPointWithinCGRectAnimationDurationTimeIntervalVoidClosure: ((CGPoint, CGRect, TimeInterval) -> Void)?

    package func positionApp(focusing: CGPoint, within: CGRect, animationDuration: TimeInterval) {
        positionAppFocusingCGPointWithinCGRectAnimationDurationTimeIntervalVoidCallsCount += 1
        positionAppFocusingCGPointWithinCGRectAnimationDurationTimeIntervalVoidReceivedArguments = (focusing: focusing, within: within, animationDuration: animationDuration)
        positionAppFocusingCGPointWithinCGRectAnimationDurationTimeIntervalVoidReceivedInvocations.append((focusing: focusing, within: within, animationDuration: animationDuration))
        positionAppFocusingCGPointWithinCGRectAnimationDurationTimeIntervalVoidClosure?(focusing, within, animationDuration)
    }

    //MARK: - positionApp

    package var positionAppYOffsetCGFloatAnimationDurationTimeIntervalVoidCallsCount = 0
    package var positionAppYOffsetCGFloatAnimationDurationTimeIntervalVoidCalled: Bool {
        return positionAppYOffsetCGFloatAnimationDurationTimeIntervalVoidCallsCount > 0
    }
    package var positionAppYOffsetCGFloatAnimationDurationTimeIntervalVoidReceivedArguments: (yOffset: CGFloat, animationDuration: TimeInterval)?
    package var positionAppYOffsetCGFloatAnimationDurationTimeIntervalVoidReceivedInvocations: [(yOffset: CGFloat, animationDuration: TimeInterval)] = []
    package var positionAppYOffsetCGFloatAnimationDurationTimeIntervalVoidClosure: ((CGFloat, TimeInterval) -> Void)?

    package func positionApp(yOffset: CGFloat, animationDuration: TimeInterval) {
        positionAppYOffsetCGFloatAnimationDurationTimeIntervalVoidCallsCount += 1
        positionAppYOffsetCGFloatAnimationDurationTimeIntervalVoidReceivedArguments = (yOffset: yOffset, animationDuration: animationDuration)
        positionAppYOffsetCGFloatAnimationDurationTimeIntervalVoidReceivedInvocations.append((yOffset: yOffset, animationDuration: animationDuration))
        positionAppYOffsetCGFloatAnimationDurationTimeIntervalVoidClosure?(yOffset, animationDuration)
    }

    //MARK: - resetAppPosition

    package var resetAppPositionVoidCallsCount = 0
    package var resetAppPositionVoidCalled: Bool {
        return resetAppPositionVoidCallsCount > 0
    }
    package var resetAppPositionVoidClosure: (() -> Void)?

    package func resetAppPosition() {
        resetAppPositionVoidCallsCount += 1
        resetAppPositionVoidClosure?()
    }

    //MARK: - resetAppWindow

    package var resetAppWindowVoidCallsCount = 0
    package var resetAppWindowVoidCalled: Bool {
        return resetAppWindowVoidCallsCount > 0
    }
    package var resetAppWindowVoidClosure: (() -> Void)?

    package func resetAppWindow() {
        resetAppWindowVoidCallsCount += 1
        resetAppWindowVoidClosure?()
    }


}
