// FormattedString.swift

import Foundation
import MemberwiseInit
import SystemAPIAliases

@MemberwiseInit(.package)
package struct FormattedString {
    package var value: String
    package var format: StringFormat
    package var arguments: [FormattedStringArgument]

    package func localizedValue(locale: Locale) -> String {
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
    package init(_ format: StringFormat) {
        self.value = format.value
        self.format = format
        self.arguments = []
    }

    package init(format: StringFormat, arguments: [FormattedStringArgument], locale: Locale = .current) {
        self.init(
            value: "",
            format: format,
            arguments: arguments
        )
        self.value = localizedValue(locale: locale)
    }

    package init(_ string: String) {
        self.init(StringFormat(string))
    }

    package init(_ localizedString: LocalizedString) {
        self.init(StringFormat(localizedString))
    }

    package var localization: Localization? {
        format.localization
    }
}

extension FormattedString: Equatable {
    package static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.format == rhs.format &&
            lhs.value == rhs.value
        // argument equality is inherently checked
        // through their inclusion in the value
    }
}

extension FormatStyle {
    func string(for input: Any, locale: Locale) -> String? {
        guard let input = input as? FormatInput else { return nil }
        let formatter = self.locale(locale)
        return formatter.format(input) as? String
    }
}
