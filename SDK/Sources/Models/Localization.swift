// Localization.swift

import Foundation

public struct Localization: Equatable {
    public var key: String
    public var bundle: Bundle?
    public var tableName: String?
    public var comment: String?

    public init(key: String, bundle: Bundle?, tableName: String?, comment: String?) {
        self.key = key
        self.bundle = bundle
        self.tableName = tableName
        self.comment = comment
    }

    public var shouldIgnore: Bool {
        bundle?.shouldIgnore == true
    }

    public func value() -> String? {
        bundle?.localizedString(forKey: key, value: key, table: tableName)
    }

    public func value(locale: Locale) -> String? {
        bundle?.localized(localeIdentifier: locale.identifier)?
            .localizedString(forKey: key, value: key, table: tableName)
    }
}
