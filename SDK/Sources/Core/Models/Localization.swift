// Localization.swift

import Foundation
import MemberwiseInit

@MemberwiseInit(.package)
package struct Localization: Equatable {
    package var key: String
    package var bundle: Bundle?
    package var tableName: String?
    package var comment: String?

    package func value() -> String {
        Bundle.main.localizedString(forKey: key, value: key, table: tableName)
    }

    package func value(locale: Locale) -> String? {
        Bundle.main.localized(localeIdentifier: locale.identifier)?
            .localizedString(forKey: key, value: key, table: tableName)
    }
}
