// SystemAPIAliases.swift

import Foundation
import SwiftUI

package enum SystemString {
    package static let initLocalizedOptionsTableBundleLocaleComment = String.init(localized:options:table:bundle:locale:comment:)
    package static let initLocalizedTableBundleLocaleComment = String.init(localized:table:bundle:locale:comment:)
    package static let initLocalizedDefaultValueOptionsTableBundleLocaleComment = String
        .init(localized:defaultValue:options:table:bundle:locale:comment:)
    package static let initLocalizedDefaultValueTableBundleLocaleComment = String.init(localized:defaultValue:table:bundle:locale:comment:)
    package static let initFormatLocaleArguments = String.init(format:locale:arguments:)
    package static let initFormatArguments = String.init(format:arguments:)
}

package enum SystemText {
    package static let initTableNameBundleComment = Text.init(_:tableName:bundle:comment:)
    package static let initVerbatim: (String) -> Text = Text.init(verbatim:)
    package static let initLocalizedStringResource: (LocalizedStringResource) -> Text = Text.init(_:)
}
