// Configuration.swift

import Foundation

public struct Configuration: Equatable {
    public var automaticallyOptInTextViews: Bool
    public var appSupportsDynamicType: Bool
    public var appSupportsDarkMode: Bool

    public init(
        automaticallyOptInTextViews: Bool = true,
        appSupportsDynamicType: Bool = true,
        appSupportsDarkMode: Bool = true
    ) {
        self.automaticallyOptInTextViews = automaticallyOptInTextViews
        self.appSupportsDynamicType = appSupportsDynamicType
        self.appSupportsDarkMode = appSupportsDarkMode
    }
}
