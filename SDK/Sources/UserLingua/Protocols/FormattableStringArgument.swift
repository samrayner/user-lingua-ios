// FormattableStringArgument.swift

import Foundation

enum FormattedStringArgument: Equatable {
    case formattedString(FormattedString)
    case cVarArg(CVarArg)
    case formattableInput(any FormatStyle, Any)

    static func == (lhs: FormattedStringArgument, rhs: FormattedStringArgument) -> Bool {
        switch (lhs, rhs) {
        case let (.formattedString(one), .formattedString(two)):
            return one == two
        case let (.cVarArg(one), .cVarArg(two)):
            return "\(one)" == "\(two)"
        case let (.formattableInput(oneFormatStyle, oneInput), .formattableInput(twoFormatStyle, twoInput)):
            guard let one = oneFormatStyle.string(for: oneInput, locale: .current) else { return false }
            let two = twoFormatStyle.string(for: twoInput, locale: .current)
            return one == two
        case (.formattedString, .cVarArg),
             (.cVarArg, .formattedString),
             (.formattedString, .formattableInput),
             (.formattableInput, .formattedString),
             (.cVarArg, .formattableInput),
             (.formattableInput, .cVarArg):
            return false
        }
    }
}
