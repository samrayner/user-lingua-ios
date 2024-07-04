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

    public var isInApp: Bool? {
        bundle?.bundleURL.absoluteString.lowercased().contains("/containers/bundle/application/")
    }

    public func value() -> String {
        Bundle.main.localizedString(forKey: key, value: key, table: tableName)
    }

    public func value(locale: Locale) -> String? {
        Bundle.main.localized(localeIdentifier: locale.identifier)?
            .localizedString(forKey: key, value: key, table: tableName)
    }
}
