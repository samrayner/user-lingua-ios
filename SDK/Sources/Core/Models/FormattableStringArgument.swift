// FormattableStringArgument.swift

import Foundation

package enum FormattedStringArgument {
    case formattedString(FormattedString)
    case cVarArg(CVarArg)
    case formattableInput(any FormatStyle, Any)
}
