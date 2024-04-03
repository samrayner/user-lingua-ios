// Theme+Global.swift

/// Globally useful mappings.
/// Very few mappings should exist here as most will be module-specific.

extension ThemeColor {
    package static let text = ThemeColor(\.foreground)
    package static let background = ThemeColor(\.background)
    package static let tint = ThemeColor(\.accent)
}

extension ThemeFont {
    package static let body = ThemeFont(\.bodyMedium)
}

extension ThemeImage {
    package static let close = ThemeImage(\.close)
}
