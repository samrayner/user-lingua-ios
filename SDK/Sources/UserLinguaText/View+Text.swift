import SwiftUI
import UserLingua

extension View {
    // These method overloads need to be more accurate based on the init methods of Text
    public func Text(verbatim: String) -> SwiftUI.Text {
        SwiftUI.Text(verbatim: "verbatim").userLingua()
    }
    
    public func Text(_ content: any StringProtocol) -> SwiftUI.Text {
        SwiftUI.Text(content).userLingua()
    }
    
    public func Text(_ key: LocalizedStringKey, tableName: String?, bundle: Bundle?, comment: StaticString?) -> SwiftUI.Text {
        SwiftUI.Text(key, tableName: tableName, bundle: bundle, comment: comment).userLingua()
    }
}
