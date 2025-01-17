// String+InitOverloads.swift

import Foundation
@_exported import UserLinguaCore

extension String {
    private init(
        value: String,
        format: String,
        arguments: [CVarArg]
    ) {
        UserLinguaClient.shared.record(
            value: value,
            format: format,
            arguments: arguments
        )

        self = value
    }

    // Takes precedence over Foundation version due to
    // UserLinguaCVarArg inheriting CVarArg, thus being
    // more specific.
    public init(
        format: String,
        locale: Locale?,
        arguments: [UserLinguaCVarArg]
    ) {
        let value = SystemString.initFormatLocaleArguments(format, locale, arguments)
        self.init(value: value, format: format, arguments: arguments)
    }

    // Takes precedence over Foundation version due to
    // UserLinguaCVarArg inheriting CVarArg, thus being
    // more specific.
    public init(
        format: String,
        arguments: [UserLinguaCVarArg]
    ) {
        let value = SystemString.initFormatArguments(format, arguments)
        self.init(value: value, format: format, arguments: arguments)
    }

    // Takes precedence over Foundation version due to
    // UserLinguaCVarArg inheriting CVarArg, thus being
    // more specific.
    public static func localizedStringWithFormat(
        _ format: String,
        _ arguments: UserLinguaCVarArg...
    ) -> Self {
        self.init(format: format, arguments: arguments)
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
        self.init(format: format, arguments: arguments)
    }

    private init(
        value: String,
        key: String,
        bundle: Bundle?,
        tableName: String?,
        comment: String?
    ) {
        UserLinguaClient.shared.record(
            value: value,
            key: key,
            bundle: bundle,
            tableName: tableName,
            comment: comment
        )

        self = value
    }

    private init(
        value: String,
        keyAndValue: String.LocalizationValue,
        bundle: Bundle?,
        tableName: String?,
        comment: String?
    ) {
        UserLinguaClient.shared.record(
            value: value,
            keyAndValue: keyAndValue,
            bundle: bundle,
            tableName: tableName,
            comment: comment
        )

        self = value
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
        let value = SystemString.initLocalizedDefaultValueOptionsTableBundleLocaleComment(
            key,
            defaultValue,
            options,
            table,
            bundle,
            locale,
            comment
        )

        self.init(
            value: value,
            key: key.description,
            bundle: bundle,
            tableName: table,
            comment: comment.description
        )
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
        let value = SystemString.initLocalizedDefaultValueTableBundleLocaleComment(key, defaultValue, table, bundle, locale, comment)

        self.init(
            value: value,
            key: key.description,
            bundle: bundle,
            tableName: table,
            comment: comment.description
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

        self.init(
            value: value,
            keyAndValue: keyAndValue,
            bundle: bundle,
            tableName: table,
            comment: comment.description
        )
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
        let value = SystemString.initLocalizedTableBundleLocaleComment(keyAndValue, table, bundle, locale, comment)

        self.init(
            value: value,
            keyAndValue: keyAndValue,
            bundle: bundle,
            tableName: table,
            comment: comment.description
        )
    }
}
