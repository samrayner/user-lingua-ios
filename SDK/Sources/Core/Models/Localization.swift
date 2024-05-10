// Localization.swift

import Foundation

package struct Localization: Equatable {
    package var key: String
    package var bundle: Bundle?
    package var tableName: String?
    package var comment: String?

    package init(key: String, bundle: Bundle?, tableName: String?, comment: String?) {
        self.key = key
        self.bundle = bundle
        self.tableName = tableName
        self.comment = comment
    }

    package var isInApp: Bool? {
        bundle?.bundleURL.absoluteString.lowercased().contains("/containers/bundle/application/")
    }

    package func value() -> String {
        Bundle.main.localizedString(forKey: key, value: key, table: tableName)
    }

    package func value(locale: Locale) -> String? {
        Bundle.main.localized(localeIdentifier: locale.identifier)?
            .localizedString(forKey: key, value: key, table: tableName)
    }
}
