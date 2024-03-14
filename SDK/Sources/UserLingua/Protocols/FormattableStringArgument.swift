// FormattableStringArgument.swift

import Foundation

enum FormattedStringArgument: Equatable {
    case formattedString(FormattedString)
    case cVarArg(CVarArg)

    static func == (lhs: FormattedStringArgument, rhs: FormattedStringArgument) -> Bool {
        switch (lhs, rhs) {
        case let (.formattedString(one), .formattedString(two)):
            one == two
        case let (.cVarArg(one), .cVarArg(two)):
            "\(one)" == "\(two)" // TODO: Improve
        case (.formattedString, .cVarArg), (.cVarArg, .formattedString):
            false
        }
    }
}
