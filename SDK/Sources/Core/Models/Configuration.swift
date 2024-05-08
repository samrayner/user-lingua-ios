// Configuration.swift

import Foundation
import HashableMacro

@Hashable
public final class Configuration: NSObject {
    @Hashed public var automaticallyOptInTextViews: Bool
    @Hashed public var appSupportsDynamicType: Bool
    @Hashed public var appSupportsDarkMode: Bool
    @Hashed public var baseLocale: Locale

    public init(
        automaticallyOptInTextViews: Bool = true,
        appSupportsDynamicType: Bool = true,
        appSupportsDarkMode: Bool = true,
        baseLocale: Locale = .current
    ) {
        self.automaticallyOptInTextViews = automaticallyOptInTextViews
        self.appSupportsDynamicType = appSupportsDynamicType
        self.appSupportsDarkMode = appSupportsDarkMode
        self.baseLocale = baseLocale
    }
}
