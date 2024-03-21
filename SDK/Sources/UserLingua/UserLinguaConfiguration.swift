// UserLinguaConfiguration.swift

import Core
import Foundation

public struct UserLinguaConfiguration: Equatable {
    public var automaticallyOptInTextViews: Bool

    public init(
        automaticallyOptInTextViews: Bool = true
    ) {
        self.automaticallyOptInTextViews = automaticallyOptInTextViews
    }
}

extension Configuration {
    init(_ userLinguaConfiguration: UserLinguaConfiguration) {
        self.init(
            automaticallyOptInTextViews: userLinguaConfiguration.automaticallyOptInTextViews
        )
    }

    var userLinguaConfiguration: UserLinguaConfiguration {
        .init(
            automaticallyOptInTextViews: automaticallyOptInTextViews
        )
    }
}
