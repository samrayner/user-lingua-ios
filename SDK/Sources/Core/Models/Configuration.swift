// Configuration.swift

import ComposableArchitecture
import Foundation

public struct Configuration: Equatable {
    package static var persistenceKey: InMemoryKey<Self> { .init("configuration") }

    public var automaticallyOptInTextViews: Bool
    public var appSupportsDynamicType: Bool
    public var appSupportsDarkMode: Bool
    public var baseLocale: Locale

    public init(
        automaticallyOptInTextViews: Bool = true,
        appSupportsDynamicType: Bool = true,
        appSupportsDarkMode: Bool = true,
        baseLocale: Locale = Locale.current
    ) {
        self.automaticallyOptInTextViews = automaticallyOptInTextViews
        self.appSupportsDynamicType = appSupportsDynamicType
        self.appSupportsDarkMode = appSupportsDarkMode
        self.baseLocale = baseLocale
    }
}
