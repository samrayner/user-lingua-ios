// RecordedString.swift

import Foundation

public struct RecordedString: Equatable {
    public var formatted: FormattedString
    public var recognizable: String
    public var recordedAt: Date = .now

    public init(_ formatted: FormattedString) {
        self.formatted = formatted
        self.recognizable = formatted.value.tokenized()
    }

    public var localization: Localization? {
        formatted.localization
    }

    public var isLocalized: Bool {
        localization != nil
    }

    public var value: String {
        formatted.value
    }

    public func localizedValue(locale: Locale) -> String {
        formatted.localizedValue(locale: locale)
    }

    public func localizedValue(
        locale: Locale,
        placeholderAttributes: [NSAttributedString.Key: Any],
        nonPlaceholderAttributes: [NSAttributedString.Key: Any] = [:],
        placeholderTransform: (String) -> String = { $0 }
    ) -> AttributedString {
        formatted.localizedValue(
            locale: locale,
            placeholderAttributes: placeholderAttributes,
            nonPlaceholderAttributes: nonPlaceholderAttributes,
            placeholderTransform: placeholderTransform
        )
    }
}

extension RecordedString {
    public init(_ localizedString: LocalizedString) {
        self.init(FormattedString(localizedString))
    }

    public init(_ string: String) {
        self.init(FormattedString(string))
    }
}
