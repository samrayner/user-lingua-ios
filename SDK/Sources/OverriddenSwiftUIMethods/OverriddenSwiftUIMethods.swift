import SwiftUI

public enum OverriddenSwiftUIMethods {
    public static let initKeyTableNameBundleComment = Text.init(_:tableName:bundle:comment:)
    
    public static let initLocalizedStringResource: (LocalizedStringResource) -> Text = Text.init(_:)
}
