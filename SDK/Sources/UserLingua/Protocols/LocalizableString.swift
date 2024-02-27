// LocalizableString.swift

import Foundation

struct StringFormat {
    var value: String
    var localization: Localization?
}

extension StringFormat {
    var localizedValue: LocalizedString? {
        localization.map { LocalizedString(value: value, localization: $0) }
    }

    var isLocalized: Bool {
        localization != nil
    }

    init(_ string: String) {
        self.value = string
        self.localization = nil
    }

    init(_ localizedString: LocalizedString) {
        self.value = localizedString.value
        self.localization = localizedString.localization
    }
}
