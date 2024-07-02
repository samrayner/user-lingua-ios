// Theme.swift

import Foundation

protocol ThemeProtocol {
    var colors: ThemeColors { get }
    var fonts: ThemeFonts { get }
    var images: ThemeImages { get }
}

public enum Theme: String {
    public static let current: Theme = .standard

    case standard

    var theme: ThemeProtocol {
        switch self {
        case .standard:
            StandardTheme()
        }
    }
}
