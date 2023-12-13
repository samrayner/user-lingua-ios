import Foundation
import SystemAPIAliases

extension String {
    /// A UserLingua overload that records the string localization asynchronously.
    public init(
        localized keyAndValue: String.LocalizationValue,
        table: String? = nil,
        bundle: Bundle? = nil,
        locale: Locale = .current,
        comment: StaticString = ""
    ) {
        let value = SystemString.initLocalizedTableBundleLocaleComment(keyAndValue, table, bundle, locale, comment)
        
        if UserLingua.shared.state == .recordingStrings, let key = keyAndValue.key {
            UserLingua.shared.db.record(
                localizedString: LocalizedString(
                    value: value,
                    localization: Localization(
                        key: key,
                        bundle: bundle,
                        tableName: table,
                        comment: String(describing: comment)
                    )
                )
            )
        }
        
        self = value
    }
    
    /// A UserLingua overload that records the string localization asynchronously.
    public init(
        localized key: StaticString,
        defaultValue: String.LocalizationValue,
        table: String? = nil,
        bundle: Bundle? = nil,
        locale: Locale = .current,
        comment: StaticString = ""
    ) {
        let value = SystemString.initLocalizedDefaultValueTableBundleLocaleComment(key, defaultValue, table, bundle, locale, comment)
        
        if UserLingua.shared.state == .recordingStrings {
            UserLingua.shared.db.record(
                localizedString: LocalizedString(
                    value: value,
                    localization: Localization(
                        key: String(describing: key),
                        bundle: bundle,
                        tableName: table,
                        comment: String(describing: comment)
                    )
                )
            )
        }
        
        self = value
    }
    
    /// A UserLingua overload that records the string localization asynchronously.
    public init(
        localized keyAndValue: String.LocalizationValue,
        options: String.LocalizationOptions,
        table: String? = nil,
        bundle: Bundle? = nil,
        locale: Locale = .current,
        comment: StaticString = ""
    ) {
        let value = SystemString.initLocalizedOptionsTableBundleLocaleComment(keyAndValue, options, table, bundle, locale, comment)
        
        if UserLingua.shared.state == .recordingStrings, let key = keyAndValue.key {
            UserLingua.shared.db.record(
                localizedString: LocalizedString(
                    value: value,
                    localization: Localization(
                        key: key,
                        bundle: bundle,
                        tableName: table,
                        comment: String(describing: comment)
                    )
                )
            )
        }
        
        self = value
    }
    
    /// A UserLingua overload that records the string localization asynchronously.
    public init(
        localized key: StaticString,
        defaultValue: String.LocalizationValue,
        options: String.LocalizationOptions,
        table: String? = nil,
        bundle: Bundle? = nil,
        locale: Locale = .current,
        comment: StaticString = ""
    ) {
        let value = SystemString.initLocalizedDefaultValueOptionsTableBundleLocaleComment(key, defaultValue, options, table, bundle, locale, comment)
        
        if UserLingua.shared.state == .recordingStrings {
            UserLingua.shared.db.record(
                localizedString: LocalizedString(
                    value: value,
                    localization: Localization(
                        key: String(describing: key),
                        bundle: bundle,
                        tableName: table,
                        comment: String(describing: comment)
                    )
                )
            )
        }
        
        self = value
    }
}
