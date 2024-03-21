// Configuration.swift

import Foundation

package struct Configuration: Equatable {
    package var automaticallyOptInTextViews: Bool

    package init(
        automaticallyOptInTextViews: Bool = true
    ) {
        self.automaticallyOptInTextViews = automaticallyOptInTextViews
    }
}
