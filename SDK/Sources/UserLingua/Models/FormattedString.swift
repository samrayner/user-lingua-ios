// FormattedString.swift

import Foundation
import SystemAPIAliases

struct FormattedString: Equatable {
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
            case let .formattableInput(formatStyle, input):
                formattedArguments.append(formatStyle.string(for: input, locale: locale) ?? "")
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

    init(format: StringFormat, arguments: [FormattedStringArgument], locale: Locale = .current) {
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
