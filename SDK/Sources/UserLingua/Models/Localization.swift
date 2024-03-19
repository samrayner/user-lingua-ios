// Localization.swift

import Foundation

struct Localization: Equatable {
    var key: String
    var bundle: Bundle?
    var tableName: String?
    var comment: String?

    func value() -> String {
        Bundle.main.unswizzledLocalizedString(forKey: key, value: key, table: tableName)
    }

    func value(locale: Locale) -> String? {
        Bundle.main.localized(localeIdentifier: locale.identifier)?
            .unswizzledLocalizedString(forKey: key, value: key, table: tableName)
    }
}
