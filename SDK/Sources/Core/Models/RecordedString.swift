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

    package var value: String {
        formatted.value
    }

    package func localizedValue(locale: Locale) -> String {
        formatted.localizedValue(locale: locale)
    }

    package func localizedValue(
        locale: Locale,
        placeholderAttributes: [NSAttributedString.Key: Any],
        nonPlaceholderAttributes: [NSAttributedString.Key: Any] = [:]
    ) -> AttributedString {
        formatted.localizedValue(
            locale: locale,
            placeholderAttributes: placeholderAttributes,
            nonPlaceholderAttributes: nonPlaceholderAttributes
        )
    }
}

extension RecordedString {
    init(_ localizedString: LocalizedString) {
        self.init(FormattedString(localizedString))
    }

    init(_ string: String) {
        self.init(FormattedString(string))
    }
}