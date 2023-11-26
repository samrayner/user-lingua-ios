import SwiftUI

public enum OverriddenSwiftUIMethods {
    public enum Text {
        public static let initWithKeyTableNameBundleComment = SwiftUI.Text.init(_:tableName:bundle:comment:)
    }
    
    public enum Button {
        public static let initWithTitleKeyAction = SwiftUI.Button.init(_:action:)
    }
}
