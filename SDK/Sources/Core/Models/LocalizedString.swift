// LocalizedString.swift

import Foundation

package struct LocalizedString {
    package var value: String
    package var localization: Localization

    package init(value: String, localization: Localization) {
        self.value = value
        self.localization = localization
    }

    package func localizedValue(locale: Locale) -> String? {
        localization.value(locale: locale)
    }
}

extension LocalizedString {
    package init(
        _ key: String,
        tableName: String? = nil,
        bundle: Bundle? = nil,
        comment: StaticString? = nil
    ) {
        let localization = Localization(
            key: key,
            bundle: bundle,
            tableName: tableName,
            comment: comment.map(\.description)
        )

        self.init(
            value: localization.value(),
            localization: localization
        )
    }
}
