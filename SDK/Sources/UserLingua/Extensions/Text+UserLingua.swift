import SwiftUI

extension Text {
    public func userLingua() -> Text {
        UserLingua.shared.processText(self)
    }
}
