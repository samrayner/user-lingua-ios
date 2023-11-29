import SwiftUI

public enum OverriddenSwiftUIMethods {
    public enum Text {
        public static let initWithKeyTableNameBundleComment = SwiftUI.Text.init(_:tableName:bundle:comment:)
        public static let initWithContent: (String) -> SwiftUI.Text = SwiftUI.Text.init(_:)
    }
}
