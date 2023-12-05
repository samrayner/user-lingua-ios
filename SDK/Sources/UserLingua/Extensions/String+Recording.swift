import Foundation

extension String {
    public init(
        localized keyAndValue: String.LocalizationValue
    ) {
        let value = String(localized: keyAndValue, table: nil)
        print(value)
        UserLingua.shared.db.record(
            localizedString: LocalizedString(
                value: value,
                localization: Localization(key: "\(keyAndValue)", bundle: nil, tableName: nil, comment: nil)
            )
        )
        self = value
    }
}

//public init(
//    localized keyAndValue: String.LocalizationValue,
//    table: String? = nil,
//    bundle: Bundle? = nil,
//    locale: Locale = .current,
//    comment: StaticString? = nil
//)
//
//public init(
//    localized key: StaticString,
//    defaultValue: String.LocalizationValue,
//    table: String? = nil,
//    bundle: Bundle? = nil,
//    locale: Locale = .current,
//    comment: StaticString? = nil
//)
//
//public init(
//    localized keyAndValue: String.LocalizationValue,
//    options: String.LocalizationOptions,
//    table: String? = nil,
//    bundle: Bundle? = nil,
//    locale: Locale = .current,
//    comment: StaticString? = nil
//)
//
//public init(
//    localized key: StaticString,
//    defaultValue: String.LocalizationValue,
//    options: String.LocalizationOptions,
//    table: String? = nil,
//    bundle: Bundle? = nil,
//    locale: Locale = .current,
//    comment: StaticString? = nil
//)
