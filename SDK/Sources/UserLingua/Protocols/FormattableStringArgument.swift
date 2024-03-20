// FormattableStringArgument.swift

import Foundation

enum FormattedStringArgument {
    case formattedString(FormattedString)
    case cVarArg(CVarArg)
    case formattableInput(any FormatStyle, Any)
}
