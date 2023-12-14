import SwiftUI

// Text conforms to this in the UserLinguaTextOptIn module.
package protocol UserLinguaOptedIn {}

extension Text {
    public func userLingua() -> Text {
        if self is UserLinguaOptedIn {
            self
        } else {
            UserLingua.shared.processText(self)
        }
    }
}
