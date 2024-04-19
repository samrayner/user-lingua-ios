// RecordedString.swift

import Foundation

package struct RecordedString: Equatable {
    package var formatted: FormattedString
    package var recognizable: String
    package var recordedAt: Date = .now

    package init(_ formatted: FormattedString) {
        self.formatted = formatted
        self.recognizable = formatted.value.tokenized()
    }

    package var localization: Localization? {
        formatted.localization
    }

    package var isLocalized: Bool {
        localization != nil
    }

    package var value: String {
        formatted.value
    }

    package func localizedValue(locale: Locale) -> String {
        formatted.localizedValue(locale: locale)
    }

    package func localizedValue(
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
    package init(_ localizedString: LocalizedString) {
        self.init(FormattedString(localizedString))
    }

    package init(_ string: String) {
        self.init(FormattedString(string))
    }
}
