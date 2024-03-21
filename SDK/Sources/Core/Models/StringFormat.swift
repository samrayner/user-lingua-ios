// StringFormat.swift

import Foundation
import MemberwiseInit

@MemberwiseInit(.package)
package struct StringFormat: Equatable {
    package var value: String
    package var localization: Localization?

    package var localized: LocalizedString? {
        localization.map { LocalizedString(value: value, localization: $0) }
    }

    package var isLocalized: Bool {
        localization != nil
    }

    package func localizedValue(locale: Locale) -> String {
        localization?.value(locale: locale) ?? value
    }
}

extension StringFormat {
    package init(_ string: String) {
        self.value = string
        self.localization = nil
    }

    package init(_ localizedString: LocalizedString) {
        self.value = localizedString.value
        self.localization = localizedString.localization
    }
}
