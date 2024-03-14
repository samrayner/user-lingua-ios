// UserLinguaConfiguration.swift

import Foundation

public struct UserLinguaConfiguration: Equatable {
    public var automaticallyOptInTextViews: Bool

    public init(
        automaticallyOptInTextViews: Bool = true
    ) {
        self.automaticallyOptInTextViews = automaticallyOptInTextViews
    }
}
