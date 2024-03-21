// LocalizedString.swift

import MemberwiseInit
import SwiftUI

@MemberwiseInit(.package)
package struct LocalizedString {
    package var value: String
    package var localization: Localization

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
