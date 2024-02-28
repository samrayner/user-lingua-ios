// FormattedString.swift

import Foundation

struct FormattedString {
    var value: String
    var format: StringFormat
    var arguments: [FormattedStringArgument]

    func value(
        locale: Locale,
        substitution substitute: (StringFormat, Locale) -> String = { format, _ in
            format.value
        }
    ) -> String {
        if arguments.isEmpty { return substitute(format, locale) }

        var formattedArguments: [CVarArg] = []

        for argument in arguments {
            switch argument {
            case let .formattedString(formattedString):
                formattedArguments.append(formattedString.value(locale: locale))
            case let .cVarArg(cVarArg):
                formattedArguments.append(cVarArg)
            }
        }

        return String(format: substitute(format, locale), arguments: formattedArguments)
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
        self.value = value(locale: locale)
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
