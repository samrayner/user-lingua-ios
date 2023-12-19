import Foundation
import SystemAPIAliases

extension String {
    // Takes precedence over Foundation version due to
    // UserLinguaCVarArg inheriting CVarArg, thus being
    // more specific.
    public init(
        format: String,
        locale: Locale?,
        arguments: [UserLinguaCVarArg]
    ) {
        let value = SystemString.initFormatLocaleArguments(format, locale, arguments)
        
        guard UserLingua.shared.state == .recordingStrings else {
            self = value
            return
        }
        
        if let localization = UserLingua.shared.db.recordedString(for: format)?.localization {
            UserLingua.shared.db.record(
                localizedString: .init(
                    value: value,
                    localization: localization
                )
            )
        } else {
            UserLingua.shared.db.record(string: value)
        }
        
        self = value
    }
    
    // Takes precedence over Foundation version due to
    // UserLinguaCVarArg inheriting CVarArg, thus being
    // more specific.
    public static func localizedStringWithFormat(
        _ format: String,
        _ arguments: UserLinguaCVarArg...
    ) -> Self {
        self.init(format: format, locale: nil, arguments: arguments)
    }
    
    // Takes precedence over Foundation version due to
    // UserLinguaCVarArg inheriting CVarArg, thus being
    // more specific.
    public init(
        format: String,
        arguments: [UserLinguaCVarArg]
    ) {
        self.init(format: format, locale: nil, arguments: arguments)
    }
    
    // Takes precedence over Foundation version due to
    // UserLinguaCVarArg inheriting CVarArg, thus being
    // more specific.
    public init(
        format: String,
        locale: Locale?,
        _ arguments: UserLinguaCVarArg...
    ) {
        self.init(format: format, locale: locale, arguments: arguments)
    }
    
    // Takes precedence over Foundation version due to
    // UserLinguaCVarArg inheriting CVarArg, thus being
    // more specific.
    public init(
        format: String,
        _ arguments: UserLinguaCVarArg...
    ) {
        self.init(format: format, locale: nil, arguments: arguments)
    }
    
    // Takes precedence over Foundation version due to comment
    // argument having a non-optional type.
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
        
        guard UserLingua.shared.state == .recordingStrings else {
            self = value
            return
        }
        
        UserLingua.shared.db.record(
            localizedString: LocalizedString(
                value: value,
                localization: Localization(
                    key: key.description,
                    bundle: bundle,
                    tableName: table,
                    comment: comment.description
                )
            )
        )
        
        self = value
    }
    
    // Takes precedence over Foundation version due to comment
    // argument having a non-optional type.
    public init(
        localized key: StaticString,
        defaultValue: String.LocalizationValue,
        table: String? = nil,
        bundle: Bundle? = nil,
        locale: Locale = .current,
        comment: StaticString = ""
    ) {
        self.init(
            localized: key,
            defaultValue: defaultValue,
            options: .init(),
            table: table,
            bundle: bundle,
            locale: locale,
            comment: comment
        )
    }
    
    // Takes precedence over Foundation version due to comment
    // argument having a non-optional type.
    public init(
        localized keyAndValue: String.LocalizationValue,
        options: String.LocalizationOptions,
        table: String? = nil,
        bundle: Bundle? = nil,
        locale: Locale = .current,
        comment: StaticString = ""
    ) {
        let value = SystemString.initLocalizedOptionsTableBundleLocaleComment(keyAndValue, options, table, bundle, locale, comment)
        
        guard UserLingua.shared.state == .recordingStrings else {
            self = value
            return
        }
        
        if let key = keyAndValue.key {
            UserLingua.shared.db.record(
                localizedString: LocalizedString(
                    value: value,
                    localization: Localization(
                        key: key,
                        bundle: bundle,
                        tableName: table,
                        comment: comment.description
                    )
                )
            )
        }
        
        self = value
    }
    
    // Takes precedence over Foundation version due to comment
    // argument having a non-optional type.
    public init(
        localized keyAndValue: String.LocalizationValue,
        table: String? = nil,
        bundle: Bundle? = nil,
        locale: Locale = .current,
        comment: StaticString = ""
    ) {
        self.init(
            localized: keyAndValue,
            options: .init(),
            table: table,
            bundle: bundle,
            locale: locale,
            comment: comment
        )
    }
}
