import Foundation
import SwiftUI

public enum SystemString {
    public static let initLocalizedTableBundleLocaleComment = String.init(localized:table:bundle:locale:comment:)
    public static let initLocalizedDefaultValueTableBundleLocaleComment = String.init(localized:defaultValue:table:bundle:locale:comment:)
    public static let initLocalizedOptionsTableBundleLocaleComment = String.init(localized:options:table:bundle:locale:comment:)
    public static let initLocalizedDefaultValueOptionsTableBundleLocaleComment = String.init(localized:defaultValue:options:table:bundle:locale:comment:)
}

public enum SystemText {
    public static let initTableNameBundleComment = Text.init(_:tableName:bundle:comment:)
    public static let initContent: (String) -> Text = Text.init(_:)
}
