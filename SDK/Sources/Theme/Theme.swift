// Theme.swift

import Foundation

protocol ThemeProtocol {
    var colors: ThemeColors { get }
    var fonts: ThemeFonts { get }
    var images: ThemeImages { get }
}

package enum Theme: String {
    package static let current: Theme = .standard

    case standard

    var theme: ThemeProtocol {
        switch self {
        case .standard:
            StandardTheme()
        }
    }
}
