// LocalizedString.swift

import SwiftUI

struct LocalizedString: Hashable {
    var value: String
    var localization: Localization

    func localizedValue(locale: Locale) -> String? {
        localization.value(locale: locale)
    }
}

extension LocalizedString {
    init(
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
