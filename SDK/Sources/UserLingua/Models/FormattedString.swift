// FormattedString.swift

import Foundation
import SystemAPIAliases

struct FormattedString {
    var value: String
    var format: StringFormat
    var arguments: [FormattedStringArgument]

    func localizedValue(locale: Locale) -> String {
        let localizedFormat = format.localizedValue(locale: locale)

        if arguments.isEmpty { return localizedFormat }

        var formattedArguments: [CVarArg] = []

        for argument in arguments {
            switch argument {
            case let .formattedString(formattedString):
                formattedArguments.append(formattedString.localizedValue(locale: locale))
            case let .cVarArg(cVarArg):
                formattedArguments.append(cVarArg)
            }
        }

        return SystemString.initFormatLocaleArguments(localizedFormat, locale, formattedArguments)
    }
}

extension FormattedString {
    init(_ format: StringFormat) {
        self.value = format.value
        self.format = format
        self.arguments = []
    }

    init(format: StringFormat, locale: Locale, arguments: [FormattedStringArgument]) {
        self.init(
            value: "",
            format: format,
            arguments: arguments
        )
        self.value = localizedValue(locale: locale)
    }

    init(_ string: String) {
        self.init(StringFormat(string))
    }

    init(_ localizedString: LocalizedString) {
        self.init(StringFormat(localizedString))
    }

    var localization: Localization? {
        format.localization
    }
}
