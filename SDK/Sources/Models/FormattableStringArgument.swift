// FormattableStringArgument.swift

import Foundation

public enum FormattedStringArgument {
    case formattedString(FormattedString)
    case cVarArg(CVarArg)
    case formattableInput(any FormatStyle, Any)

    func value(locale: Locale) -> CVarArg {
        switch self {
        case let .formattedString(formattedString):
            formattedString.localizedValue(locale: locale)
        case let .cVarArg(cVarArg):
            cVarArg
        case let .formattableInput(formatStyle, input):
            formatStyle.string(for: input, locale: locale) ?? ""
        }
    }
}
