// Theme+Components.swift

/// Globally useful mappings.
/// Very few mappings should exist here as most will be module-specific.

extension ThemeColor {
    static let horizontalRule = ThemeColor(\.surface)

    enum Button {
        enum Primary {
            static let text = ThemeColor(\.onPrimary)
            static let textDisabled = ThemeColor(\.foreground)
            static let background = ThemeColor(\.primary)
            static let backgroundDisabled = ThemeColor(\.surface)
        }
    }
}

extension ThemeFont {
    enum Button {
        static let primary = ThemeFont(\.button)
    }
}
