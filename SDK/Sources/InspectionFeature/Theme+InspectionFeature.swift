// Theme+InspectionFeature.swift

import Theme

extension ThemeColor {
    static let suggestionFieldBackground = ThemeColor(\.background)
    static let suggestionFieldBorder = ThemeColor(\.foreground)
    static let placeholderHighlight = ThemeColor(\.accent)
}

extension ThemeImage {
    package static let increaseTextSize = ThemeImage(\.increaseTextSize)
    package static let decreaseTextSize = ThemeImage(\.decreaseTextSize)
    package static let toggleDarkMode = ThemeImage(\.toggleDarkMode)
    package static let untoggleDarkMode = ThemeImage(\.untoggleDarkMode)
}
