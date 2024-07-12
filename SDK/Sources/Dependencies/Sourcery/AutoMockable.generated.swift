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
import Models























public class AllDependenciesMock: AllDependencies {

    public init() {}

    public var appViewModel: UserLinguaObservable {
        get { return underlyingAppViewModel }
        set(value) { underlyingAppViewModel = value }
    }
    public var underlyingAppViewModel: (UserLinguaObservable)!
    public var notificationCenter: NotificationCenter {
        get { return underlyingNotificationCenter }
        set(value) { underlyingNotificationCenter = value }
    }
    public var underlyingNotificationCenter: (NotificationCenter)!
    public var deviceOrientationObservable: DeviceOrientationObservable {
        get { return underlyingDeviceOrientationObservable }
        set(value) { underlyingDeviceOrientationObservable = value }
    }
    public var underlyingDeviceOrientationObservable: (DeviceOrientationObservable)!
    public var contentSizeCategoryService: ContentSizeCategoryServiceProtocol {
        get { return underlyingContentSizeCategoryService }
        set(value) { underlyingContentSizeCategoryService = value }
    }
    public var underlyingContentSizeCategoryService: (ContentSizeCategoryServiceProtocol)!
    public var stringExtractor: any StringExtractorProtocol {
        get { return underlyingStringExtractor }
        set(value) { underlyingStringExtractor = value }
    }
    public var underlyingStringExtractor: (any StringExtractorProtocol)!
    public var stringRecognizer: any StringRecognizerProtocol {
        get { return underlyingStringRecognizer }
        set(value) { underlyingStringRecognizer = value }
    }
    public var underlyingStringRecognizer: (any StringRecognizerProtocol)!
    public var stringsRepository: any StringsRepositoryProtocol {
        get { return underlyingStringsRepository }
        set(value) { underlyingStringsRepository = value }
    }
    public var underlyingStringsRepository: (any StringsRepositoryProtocol)!
    public var suggestionsRepository: any SuggestionsRepositoryProtocol {
        get { return underlyingSuggestionsRepository }
        set(value) { underlyingSuggestionsRepository = value }
    }
    public var underlyingSuggestionsRepository: (any SuggestionsRepositoryProtocol)!
    public var windowService: any WindowServiceProtocol {
        get { return underlyingWindowService }
        set(value) { underlyingWindowService = value }
    }
    public var underlyingWindowService: (any WindowServiceProtocol)!
    public var swizzler: any SwizzlerProtocol {
        get { return underlyingSwizzler }
        set(value) { underlyingSwizzler = value }
    }
    public var underlyingSwizzler: (any SwizzlerProtocol)!



}
public class ContentSizeCategoryServiceProtocolMock: ContentSizeCategoryServiceProtocol {

    public init() {}

    public var systemContentSizeCategory: UIContentSizeCategory {
        get { return underlyingSystemContentSizeCategory }
        set(value) { underlyingSystemContentSizeCategory = value }
    }
    public var underlyingSystemContentSizeCategory: (UIContentSizeCategory)!
    public var appContentSizeCategory: UIContentSizeCategory {
        get { return underlyingAppContentSizeCategory }
        set(value) { underlyingAppContentSizeCategory = value }
    }
    public var underlyingAppContentSizeCategory: (UIContentSizeCategory)!


    //MARK: - incrementAppContentSizeCategory

    public var incrementAppContentSizeCategoryVoidCallsCount = 0
    public var incrementAppContentSizeCategoryVoidCalled: Bool {
        return incrementAppContentSizeCategoryVoidCallsCount > 0
    }
    public var incrementAppContentSizeCategoryVoidClosure: (() -> Void)?

    public func incrementAppContentSizeCategory() {
        incrementAppContentSizeCategoryVoidCallsCount += 1
        incrementAppContentSizeCategoryVoidClosure?()
    }

    //MARK: - decrementAppContentSizeCategory

    public var decrementAppContentSizeCategoryVoidCallsCount = 0
    public var decrementAppContentSizeCategoryVoidCalled: Bool {
        return decrementAppContentSizeCategoryVoidCallsCount > 0
    }
    public var decrementAppContentSizeCategoryVoidClosure: (() -> Void)?

    public func decrementAppContentSizeCategory() {
        decrementAppContentSizeCategoryVoidCallsCount += 1
        decrementAppContentSizeCategoryVoidClosure?()
    }

    //MARK: - resetAppContentSizeCategory

    public var resetAppContentSizeCategoryVoidCallsCount = 0
    public var resetAppContentSizeCategoryVoidCalled: Bool {
        return resetAppContentSizeCategoryVoidCallsCount > 0
    }
    public var resetAppContentSizeCategoryVoidClosure: (() -> Void)?

    public func resetAppContentSizeCategory() {
        resetAppContentSizeCategoryVoidCallsCount += 1
        resetAppContentSizeCategoryVoidClosure?()
    }


}
public class StringExtractorProtocolMock: StringExtractorProtocol {

    public init() {}



    //MARK: - formattedString

    public var formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringCallsCount = 0
    public var formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringCalled: Bool {
        return formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringCallsCount > 0
    }
    public var formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringReceivedArguments: (localizedStringKey: LocalizedStringKey, tableName: String?, bundle: Bundle?, comment: String?)?
    public var formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringReceivedInvocations: [(localizedStringKey: LocalizedStringKey, tableName: String?, bundle: Bundle?, comment: String?)] = []
    public var formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringReturnValue: FormattedString!
    public var formattedStringLocalizedStringKeyLocalizedStringKeyTableNameStringBundleBundleCommentStringFormattedStringClosure: ((LocalizedStringKey, String?, Bundle?, String?) -> FormattedString)?

    public func formattedString(localizedStringKey: LocalizedStringKey, tableName: String?, bundle: Bundle?, comment: String?) -> FormattedString {
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
public class StringRecognizerProtocolMock: StringRecognizerProtocol {

    public init() {}



    //MARK: - recognizeStrings

    public var recognizeStringsInImageUIImageAnyPublisherRecognizedStringStringRecognizerErrorCallsCount = 0
    public var recognizeStringsInImageUIImageAnyPublisherRecognizedStringStringRecognizerErrorCalled: Bool {
        return recognizeStringsInImageUIImageAnyPublisherRecognizedStringStringRecognizerErrorCallsCount > 0
    }
    public var recognizeStringsInImageUIImageAnyPublisherRecognizedStringStringRecognizerErrorReceivedImage: (UIImage)?
    public var recognizeStringsInImageUIImageAnyPublisherRecognizedStringStringRecognizerErrorReceivedInvocations: [(UIImage)] = []
    public var recognizeStringsInImageUIImageAnyPublisherRecognizedStringStringRecognizerErrorReturnValue: AnyPublisher<[RecognizedString], StringRecognizerError>!
    public var recognizeStringsInImageUIImageAnyPublisherRecognizedStringStringRecognizerErrorClosure: ((UIImage) -> AnyPublisher<[RecognizedString], StringRecognizerError>)?

    public func recognizeStrings(in image: UIImage) -> AnyPublisher<[RecognizedString], StringRecognizerError> {
        recognizeStringsInImageUIImageAnyPublisherRecognizedStringStringRecognizerErrorCallsCount += 1
        recognizeStringsInImageUIImageAnyPublisherRecognizedStringStringRecognizerErrorReceivedImage = image
        recognizeStringsInImageUIImageAnyPublisherRecognizedStringStringRecognizerErrorReceivedInvocations.append(image)
        if let recognizeStringsInImageUIImageAnyPublisherRecognizedStringStringRecognizerErrorClosure = recognizeStringsInImageUIImageAnyPublisherRecognizedStringStringRecognizerErrorClosure {
            return recognizeStringsInImageUIImageAnyPublisherRecognizedStringStringRecognizerErrorClosure(image)
        } else {
            return recognizeStringsInImageUIImageAnyPublisherRecognizedStringStringRecognizerErrorReturnValue
        }
    }

    //MARK: - cancel

    public var cancelVoidCallsCount = 0
    public var cancelVoidCalled: Bool {
        return cancelVoidCallsCount > 0
    }
    public var cancelVoidClosure: (() -> Void)?

    public func cancel() {
        cancelVoidCallsCount += 1
        cancelVoidClosure?()
    }


}
public class StringsRepositoryProtocolMock: StringsRepositoryProtocol {

    public init() {}



    //MARK: - record

    public var recordFormattedFormattedStringVoidCallsCount = 0
    public var recordFormattedFormattedStringVoidCalled: Bool {
        return recordFormattedFormattedStringVoidCallsCount > 0
    }
    public var recordFormattedFormattedStringVoidReceivedFormatted: (FormattedString)?
    public var recordFormattedFormattedStringVoidReceivedInvocations: [(FormattedString)] = []
    public var recordFormattedFormattedStringVoidClosure: ((FormattedString) -> Void)?

    public func record(formatted: FormattedString) {
        recordFormattedFormattedStringVoidCallsCount += 1
        recordFormattedFormattedStringVoidReceivedFormatted = formatted
        recordFormattedFormattedStringVoidReceivedInvocations.append(formatted)
        recordFormattedFormattedStringVoidClosure?(formatted)
    }

    //MARK: - record

    public var recordLocalizedLocalizedStringVoidCallsCount = 0
    public var recordLocalizedLocalizedStringVoidCalled: Bool {
        return recordLocalizedLocalizedStringVoidCallsCount > 0
    }
    public var recordLocalizedLocalizedStringVoidReceivedLocalized: (LocalizedString)?
    public var recordLocalizedLocalizedStringVoidReceivedInvocations: [(LocalizedString)] = []
    public var recordLocalizedLocalizedStringVoidClosure: ((LocalizedString) -> Void)?

    public func record(localized: LocalizedString) {
        recordLocalizedLocalizedStringVoidCallsCount += 1
        recordLocalizedLocalizedStringVoidReceivedLocalized = localized
        recordLocalizedLocalizedStringVoidReceivedInvocations.append(localized)
        recordLocalizedLocalizedStringVoidClosure?(localized)
    }

    //MARK: - record

    public var recordStringStringVoidCallsCount = 0
    public var recordStringStringVoidCalled: Bool {
        return recordStringStringVoidCallsCount > 0
    }
    public var recordStringStringVoidReceivedString: (String)?
    public var recordStringStringVoidReceivedInvocations: [(String)] = []
    public var recordStringStringVoidClosure: ((String) -> Void)?

    public func record(string: String) {
        recordStringStringVoidCallsCount += 1
        recordStringStringVoidReceivedString = string
        recordStringStringVoidReceivedInvocations.append(string)
        recordStringStringVoidClosure?(string)
    }

    //MARK: - recordedStrings

    public var recordedStringsRecordedStringCallsCount = 0
    public var recordedStringsRecordedStringCalled: Bool {
        return recordedStringsRecordedStringCallsCount > 0
    }
    public var recordedStringsRecordedStringReturnValue: [RecordedString]!
    public var recordedStringsRecordedStringClosure: (() -> [RecordedString])?

    public func recordedStrings() -> [RecordedString] {
        recordedStringsRecordedStringCallsCount += 1
        if let recordedStringsRecordedStringClosure = recordedStringsRecordedStringClosure {
            return recordedStringsRecordedStringClosure()
        } else {
            return recordedStringsRecordedStringReturnValue
        }
    }

    //MARK: - recordedString

    public var recordedStringFormattedFormattedStringRecordedStringCallsCount = 0
    public var recordedStringFormattedFormattedStringRecordedStringCalled: Bool {
        return recordedStringFormattedFormattedStringRecordedStringCallsCount > 0
    }
    public var recordedStringFormattedFormattedStringRecordedStringReceivedFormatted: (FormattedString)?
    public var recordedStringFormattedFormattedStringRecordedStringReceivedInvocations: [(FormattedString)] = []
    public var recordedStringFormattedFormattedStringRecordedStringReturnValue: RecordedString?
    public var recordedStringFormattedFormattedStringRecordedStringClosure: ((FormattedString) -> RecordedString?)?

    public func recordedString(formatted: FormattedString) -> RecordedString? {
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

    public var recordedStringLocalizedLocalizedStringRecordedStringCallsCount = 0
    public var recordedStringLocalizedLocalizedStringRecordedStringCalled: Bool {
        return recordedStringLocalizedLocalizedStringRecordedStringCallsCount > 0
    }
    public var recordedStringLocalizedLocalizedStringRecordedStringReceivedLocalized: (LocalizedString)?
    public var recordedStringLocalizedLocalizedStringRecordedStringReceivedInvocations: [(LocalizedString)] = []
    public var recordedStringLocalizedLocalizedStringRecordedStringReturnValue: RecordedString?
    public var recordedStringLocalizedLocalizedStringRecordedStringClosure: ((LocalizedString) -> RecordedString?)?

    public func recordedString(localized: LocalizedString) -> RecordedString? {
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

    public var recordedStringStringStringRecordedStringCallsCount = 0
    public var recordedStringStringStringRecordedStringCalled: Bool {
        return recordedStringStringStringRecordedStringCallsCount > 0
    }
    public var recordedStringStringStringRecordedStringReceivedString: (String)?
    public var recordedStringStringStringRecordedStringReceivedInvocations: [(String)] = []
    public var recordedStringStringStringRecordedStringReturnValue: RecordedString?
    public var recordedStringStringStringRecordedStringClosure: ((String) -> RecordedString?)?

    public func recordedString(string: String) -> RecordedString? {
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
public class SuggestionsRepositoryProtocolMock: SuggestionsRepositoryProtocol {

    public init() {}



    //MARK: - saveSuggestion

    public var saveSuggestionSuggestionSuggestionVoidCallsCount = 0
    public var saveSuggestionSuggestionSuggestionVoidCalled: Bool {
        return saveSuggestionSuggestionSuggestionVoidCallsCount > 0
    }
    public var saveSuggestionSuggestionSuggestionVoidReceivedSuggestion: (Suggestion)?
    public var saveSuggestionSuggestionSuggestionVoidReceivedInvocations: [(Suggestion)] = []
    public var saveSuggestionSuggestionSuggestionVoidClosure: ((Suggestion) -> Void)?

    public func saveSuggestion(_ suggestion: Suggestion) {
        saveSuggestionSuggestionSuggestionVoidCallsCount += 1
        saveSuggestionSuggestionSuggestionVoidReceivedSuggestion = suggestion
        saveSuggestionSuggestionSuggestionVoidReceivedInvocations.append(suggestion)
        saveSuggestionSuggestionSuggestionVoidClosure?(suggestion)
    }

    //MARK: - suggestion

    public var suggestionForOriginalStringLocaleLocaleSuggestionCallsCount = 0
    public var suggestionForOriginalStringLocaleLocaleSuggestionCalled: Bool {
        return suggestionForOriginalStringLocaleLocaleSuggestionCallsCount > 0
    }
    public var suggestionForOriginalStringLocaleLocaleSuggestionReceivedArguments: (original: String, locale: Locale)?
    public var suggestionForOriginalStringLocaleLocaleSuggestionReceivedInvocations: [(original: String, locale: Locale)] = []
    public var suggestionForOriginalStringLocaleLocaleSuggestionReturnValue: Suggestion?
    public var suggestionForOriginalStringLocaleLocaleSuggestionClosure: ((String, Locale) -> Suggestion?)?

    public func suggestion(for original: String, locale: Locale) -> Suggestion? {
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
public class SwizzlerProtocolMock: SwizzlerProtocol {

    public init() {}



    //MARK: - swizzleForForeground

    public var swizzleForForegroundVoidCallsCount = 0
    public var swizzleForForegroundVoidCalled: Bool {
        return swizzleForForegroundVoidCallsCount > 0
    }
    public var swizzleForForegroundVoidClosure: (() -> Void)?

    public func swizzleForForeground() {
        swizzleForForegroundVoidCallsCount += 1
        swizzleForForegroundVoidClosure?()
    }

    //MARK: - unswizzleForForeground

    public var unswizzleForForegroundVoidCallsCount = 0
    public var unswizzleForForegroundVoidCalled: Bool {
        return unswizzleForForegroundVoidCallsCount > 0
    }
    public var unswizzleForForegroundVoidClosure: (() -> Void)?

    public func unswizzleForForeground() {
        unswizzleForForegroundVoidCallsCount += 1
        unswizzleForForegroundVoidClosure?()
    }

    //MARK: - swizzleForBackground

    public var swizzleForBackgroundVoidCallsCount = 0
    public var swizzleForBackgroundVoidCalled: Bool {
        return swizzleForBackgroundVoidCallsCount > 0
    }
    public var swizzleForBackgroundVoidClosure: (() -> Void)?

    public func swizzleForBackground() {
        swizzleForBackgroundVoidCallsCount += 1
        swizzleForBackgroundVoidClosure?()
    }

    //MARK: - unswizzleForBackground

    public var unswizzleForBackgroundVoidCallsCount = 0
    public var unswizzleForBackgroundVoidCalled: Bool {
        return unswizzleForBackgroundVoidCallsCount > 0
    }
    public var unswizzleForBackgroundVoidClosure: (() -> Void)?

    public func unswizzleForBackground() {
        unswizzleForBackgroundVoidCallsCount += 1
        unswizzleForBackgroundVoidClosure?()
    }


}
public class WindowServiceProtocolMock: WindowServiceProtocol {

    public init() {}

    public var userLinguaWindow: UIWindow {
        get { return underlyingUserLinguaWindow }
        set(value) { underlyingUserLinguaWindow = value }
    }
    public var underlyingUserLinguaWindow: (UIWindow)!
    public var appUIStyle: UIUserInterfaceStyle {
        get { return underlyingAppUIStyle }
        set(value) { underlyingAppUIStyle = value }
    }
    public var underlyingAppUIStyle: (UIUserInterfaceStyle)!
    public var appYOffset: CGFloat {
        get { return underlyingAppYOffset }
        set(value) { underlyingAppYOffset = value }
    }
    public var underlyingAppYOffset: (CGFloat)!


    //MARK: - setRootView

    public var setRootViewSomeViewVoidCallsCount = 0
    public var setRootViewSomeViewVoidCalled: Bool {
        return setRootViewSomeViewVoidCallsCount > 0
    }
    public var setRootViewSomeViewVoidReceived: (any View)?
    public var setRootViewSomeViewVoidReceivedInvocations: [(any View)] = []
    public var setRootViewSomeViewVoidClosure: ((any View) -> Void)?

    public func setRootView(_ arg0: some View) {
        setRootViewSomeViewVoidCallsCount += 1
        setRootViewSomeViewVoidReceived = arg0
        setRootViewSomeViewVoidReceivedInvocations.append(arg0)
        setRootViewSomeViewVoidClosure?(arg0)
    }

    //MARK: - screenshotAppWindow

    public var screenshotAppWindowUIImageCallsCount = 0
    public var screenshotAppWindowUIImageCalled: Bool {
        return screenshotAppWindowUIImageCallsCount > 0
    }
    public var screenshotAppWindowUIImageReturnValue: UIImage?
    public var screenshotAppWindowUIImageClosure: (() -> UIImage?)?

    public func screenshotAppWindow() -> UIImage? {
        screenshotAppWindowUIImageCallsCount += 1
        if let screenshotAppWindowUIImageClosure = screenshotAppWindowUIImageClosure {
            return screenshotAppWindowUIImageClosure()
        } else {
            return screenshotAppWindowUIImageReturnValue
        }
    }

    //MARK: - showWindow

    public var showWindowVoidCallsCount = 0
    public var showWindowVoidCalled: Bool {
        return showWindowVoidCallsCount > 0
    }
    public var showWindowVoidClosure: (() -> Void)?

    public func showWindow() {
        showWindowVoidCallsCount += 1
        showWindowVoidClosure?()
    }

    //MARK: - hideWindow

    public var hideWindowVoidCallsCount = 0
    public var hideWindowVoidCalled: Bool {
        return hideWindowVoidCallsCount > 0
    }
    public var hideWindowVoidClosure: (() -> Void)?

    public func hideWindow() {
        hideWindowVoidCallsCount += 1
        hideWindowVoidClosure?()
    }

    //MARK: - toggleDarkMode

    public var toggleDarkModeVoidCallsCount = 0
    public var toggleDarkModeVoidCalled: Bool {
        return toggleDarkModeVoidCallsCount > 0
    }
    public var toggleDarkModeVoidClosure: (() -> Void)?

    public func toggleDarkMode() {
        toggleDarkModeVoidCallsCount += 1
        toggleDarkModeVoidClosure?()
    }

    //MARK: - positionApp

    public var positionAppFocusingCGPointWithinCGRectAnimationDurationTimeIntervalVoidCallsCount = 0
    public var positionAppFocusingCGPointWithinCGRectAnimationDurationTimeIntervalVoidCalled: Bool {
        return positionAppFocusingCGPointWithinCGRectAnimationDurationTimeIntervalVoidCallsCount > 0
    }
    public var positionAppFocusingCGPointWithinCGRectAnimationDurationTimeIntervalVoidReceivedArguments: (focusing: CGPoint, within: CGRect, animationDuration: TimeInterval)?
    public var positionAppFocusingCGPointWithinCGRectAnimationDurationTimeIntervalVoidReceivedInvocations: [(focusing: CGPoint, within: CGRect, animationDuration: TimeInterval)] = []
    public var positionAppFocusingCGPointWithinCGRectAnimationDurationTimeIntervalVoidClosure: ((CGPoint, CGRect, TimeInterval) -> Void)?

    public func positionApp(focusing: CGPoint, within: CGRect, animationDuration: TimeInterval) {
        positionAppFocusingCGPointWithinCGRectAnimationDurationTimeIntervalVoidCallsCount += 1
        positionAppFocusingCGPointWithinCGRectAnimationDurationTimeIntervalVoidReceivedArguments = (focusing: focusing, within: within, animationDuration: animationDuration)
        positionAppFocusingCGPointWithinCGRectAnimationDurationTimeIntervalVoidReceivedInvocations.append((focusing: focusing, within: within, animationDuration: animationDuration))
        positionAppFocusingCGPointWithinCGRectAnimationDurationTimeIntervalVoidClosure?(focusing, within, animationDuration)
    }

    //MARK: - positionApp

    public var positionAppYOffsetCGFloatAnimationDurationTimeIntervalVoidCallsCount = 0
    public var positionAppYOffsetCGFloatAnimationDurationTimeIntervalVoidCalled: Bool {
        return positionAppYOffsetCGFloatAnimationDurationTimeIntervalVoidCallsCount > 0
    }
    public var positionAppYOffsetCGFloatAnimationDurationTimeIntervalVoidReceivedArguments: (yOffset: CGFloat, animationDuration: TimeInterval)?
    public var positionAppYOffsetCGFloatAnimationDurationTimeIntervalVoidReceivedInvocations: [(yOffset: CGFloat, animationDuration: TimeInterval)] = []
    public var positionAppYOffsetCGFloatAnimationDurationTimeIntervalVoidClosure: ((CGFloat, TimeInterval) -> Void)?

    public func positionApp(yOffset: CGFloat, animationDuration: TimeInterval) {
        positionAppYOffsetCGFloatAnimationDurationTimeIntervalVoidCallsCount += 1
        positionAppYOffsetCGFloatAnimationDurationTimeIntervalVoidReceivedArguments = (yOffset: yOffset, animationDuration: animationDuration)
        positionAppYOffsetCGFloatAnimationDurationTimeIntervalVoidReceivedInvocations.append((yOffset: yOffset, animationDuration: animationDuration))
        positionAppYOffsetCGFloatAnimationDurationTimeIntervalVoidClosure?(yOffset, animationDuration)
    }

    //MARK: - resetAppPosition

    public var resetAppPositionVoidCallsCount = 0
    public var resetAppPositionVoidCalled: Bool {
        return resetAppPositionVoidCallsCount > 0
    }
    public var resetAppPositionVoidClosure: (() -> Void)?

    public func resetAppPosition() {
        resetAppPositionVoidCallsCount += 1
        resetAppPositionVoidClosure?()
    }

    //MARK: - resetAppWindow

    public var resetAppWindowVoidCallsCount = 0
    public var resetAppWindowVoidCalled: Bool {
        return resetAppWindowVoidCallsCount > 0
    }
    public var resetAppWindowVoidClosure: (() -> Void)?

    public func resetAppWindow() {
        resetAppWindowVoidCallsCount += 1
        resetAppWindowVoidClosure?()
    }


}
