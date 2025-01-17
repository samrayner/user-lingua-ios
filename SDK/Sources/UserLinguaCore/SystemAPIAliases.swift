// SystemAPIAliases.swift

import Foundation
import SwiftUI

public enum SystemString {
    public static let initLocalizedOptionsTableBundleLocaleComment = String.init(localized:options:table:bundle:locale:comment:)
    public static let initLocalizedTableBundleLocaleComment = String.init(localized:table:bundle:locale:comment:)
    public static let initLocalizedDefaultValueOptionsTableBundleLocaleComment = String
        .init(localized:defaultValue:options:table:bundle:locale:comment:)
    public static let initLocalizedDefaultValueTableBundleLocaleComment = String.init(localized:defaultValue:table:bundle:locale:comment:)
    public static let initFormatLocaleArguments = String.init(format:locale:arguments:)
    public static let initFormatArguments = String.init(format:arguments:)
}

public enum SystemText {
    public static let initTableNameBundleComment = Text.init(_:tableName:bundle:comment:)
    public static let initVerbatim: (String) -> Text = Text.init(verbatim:)
    public static let initLocalizedStringResource: (LocalizedStringResource) -> Text = Text.init(_:)
}
