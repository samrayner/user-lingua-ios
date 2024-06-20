// Configuration.swift

import Foundation
import SwiftUI

// sourcery: AutoMockable
public protocol ConfigurationProtocol {
    var automaticallyOptInTextViews: Bool { get set }
    var appSupportsDynamicType: Bool { get set }
    var appSupportsDarkMode: Bool { get set }
    var baseLocale: Locale { get set }
}

public final class Configuration: ConfigurationProtocol, ObservableObject {
    @Published public var automaticallyOptInTextViews: Bool
    @Published public var appSupportsDynamicType: Bool
    @Published public var appSupportsDarkMode: Bool
    @Published public var baseLocale: Locale

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
