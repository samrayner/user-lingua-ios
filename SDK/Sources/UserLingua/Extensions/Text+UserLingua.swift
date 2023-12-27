// Text+UserLingua.swift

import SwiftUI

// Text conforms to this in the UserLinguaTextOptIn module.
package protocol AutomaticallyOptedInToUserLingua {}

extension Text {
    public func userLingua() -> Text {
        if self is AutomaticallyOptedInToUserLingua {
            self
        } else {
            UserLingua.shared.processText(self)
        }
    }
}
