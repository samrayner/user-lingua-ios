// FormattableStringArgument.swift

import AnyCodable
import CodableCVarArg
import Foundation

public struct AnyFormattableInput: Codable {
    let anyFormatStyle: Any
    let anyInput: Any

    init<F: FormatStyle>(_ formatStyle: F, input: F.FormatInput) {
        self.anyFormatStyle = formatStyle
        self.anyInput = input
    }
}

public enum FormattedStringArgument: Codable {
    case formattedString(FormattedString)
    case cVarArg(CodableCVarArg)
    case formattableInput(AnyFormattableInput)

    func value(locale: Locale) -> CVarArg {
        switch self {
        case let .formattedString(formattedString):
            formattedString.localizedValue(locale: locale)
        case let .cVarArg(codableCVarArg):
            codableCVarArg.value
        case let .formattableInput(formattableInput):
            formattableInput.formatStyle.string(for: formattableInput.input, locale: locale) ?? ""
        }
    }
}
