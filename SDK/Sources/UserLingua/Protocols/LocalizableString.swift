// LocalizableString.swift

import Foundation

struct StringFormat: Equatable {
    var value: String
    var localization: Localization?

    var localized: LocalizedString? {
        localization.map { LocalizedString(value: value, localization: $0) }
    }

    var isLocalized: Bool {
        localization != nil
    }

    func localizedValue(locale: Locale) -> String {
        localization?.value(locale: locale) ?? value
    }
}

extension StringFormat {
    init(_ string: String) {
        self.value = string
        self.localization = nil
    }

    init(_ localizedString: LocalizedString) {
        self.value = localizedString.value
        self.localization = localizedString.localization
    }
}
