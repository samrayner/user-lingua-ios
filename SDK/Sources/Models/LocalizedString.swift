// LocalizedString.swift

import Foundation
import Utilities

public struct LocalizedString {
    public var value: String
    public var localization: Localization

    public init(value: String, localization: Localization) {
        self.value = value
        self.localization = localization
    }

    public func localizedValue(locale: Locale) -> String? {
        localization.value(locale: locale)
    }
}

extension LocalizedString {
    public init(
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

    public init(_ localizedStringResource: LocalizedStringResource) {
        self.init(
            localizedStringResource.key,
            tableName: localizedStringResource.table,
            bundle: localizedStringResource.bundle,
            comment: nil
        )
    }
}
