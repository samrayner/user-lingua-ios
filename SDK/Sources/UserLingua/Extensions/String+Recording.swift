import Foundation
import SystemAPIAliases

extension String {
    public init(
        localized keyAndValue: String.LocalizationValue,
        table: String? = nil,
        bundle: Bundle = .main,
        locale: Locale = .current,
        comment: StaticString? = nil
    ) {
        let value = SystemString.initLocalizedTableBundleLocaleComment(keyAndValue, table, bundle, locale, comment)
        UserLingua.shared.db.record(
            localizedString: LocalizedString(
                value: value,
                localization: Localization(
                    key: String(describing: keyAndValue),
                    bundle: bundle,
                    tableName: table,
                    comment: String(describing: comment)
                )
            )
        )
        self = value
    }
    
    public init(
        localized key: StaticString,
        defaultValue: String.LocalizationValue,
        table: String? = nil,
        bundle: Bundle = .main,
        locale: Locale = .current,
        comment: StaticString? = nil
    ) {
        let value = SystemString.initLocalizedDefaultValueTableBundleLocaleComment(key, defaultValue, table, bundle, locale, comment)
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
        self = value
    }
    
    public init(
        localized keyAndValue: String.LocalizationValue,
        options: String.LocalizationOptions,
        table: String? = nil,
        bundle: Bundle = .main,
        locale: Locale = .current,
        comment: StaticString? = nil
    ) {
        let value = SystemString.initLocalizedOptionsTableBundleLocaleComment(keyAndValue, options, table, bundle, locale, comment)
        UserLingua.shared.db.record(
            localizedString: LocalizedString(
                value: value,
                localization: Localization(
                    key: String(describing: keyAndValue),
                    bundle: bundle,
                    tableName: table,
                    comment: String(describing: comment)
                )
            )
        )
        self = value
    }
    
    public init(
        localized key: StaticString,
        defaultValue: String.LocalizationValue,
        options: String.LocalizationOptions,
        table: String? = nil,
        bundle: Bundle = .main,
        locale: Locale = .current,
        comment: StaticString? = nil
    ) {
        let value = SystemString.initLocalizedDefaultValueOptionsTableBundleLocaleComment(key, defaultValue, options, table, bundle, locale, comment)
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
        self = value
    }
}
