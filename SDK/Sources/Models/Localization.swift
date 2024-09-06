// Localization.swift

import Foundation
import Utilities

public struct Localization: Equatable, Codable {
    public var key: String
    public var bundleURL: URL?
    public var tableName: String?
    public var comment: String?

    var bundle: Bundle? {
        bundleURL.flatMap(Bundle.init)
    }

    public init(key: String, bundle: Bundle?, tableName: String?, comment: String?) {
        self.key = key
        self.bundleURL = bundle?.bundleURL
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
