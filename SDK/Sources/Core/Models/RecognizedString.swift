// RecognizedString.swift

import Foundation
import MemberwiseInit

@MemberwiseInit(.package)
package struct RecognizedString: Equatable {
    package let id = UUID()
    package var recordedString: RecordedString
    package var lines: [RecognizedLine]

    package var localization: Localization? {
        recordedString.localization
    }

    package var value: String {
        recordedString.value
    }

    package func localizedValue(locale: Locale) -> String {
        recordedString.localizedValue(locale: locale)
    }

    package func localizedValue(
        locale: Locale,
        placeholderAttributes: [NSAttributedString.Key: Any],
        nonPlaceholderAttributes: [NSAttributedString.Key: Any] = [:],
        placeholderTransform: (String) -> String = { $0 }
    ) -> AttributedString {
        recordedString.localizedValue(
            locale: locale,
            placeholderAttributes: placeholderAttributes,
            nonPlaceholderAttributes: nonPlaceholderAttributes,
            placeholderTransform: placeholderTransform
        )
    }
}

extension RecognizedString: Identifiable {}
