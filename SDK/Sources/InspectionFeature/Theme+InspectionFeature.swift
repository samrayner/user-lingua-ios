// Theme+InspectionFeature.swift

import Theme

extension ThemeColor {
    static let suggestionFieldBackground = ThemeColor(\.well)
    static let placeholderHighlight = ThemeColor(\.primary)
    static let localePickerButtonBackground = ThemeColor(\.surface)
    static let localePickerButtonBackgroundSelected = ThemeColor(\.primary)
    static let localePickerButtonText = ThemeColor(\.foreground)
    static let localePickerButtonTextSelected = ThemeColor(\.onPrimary)
}

extension ThemeImage {
    package static let increaseTextSize = ThemeImage(\.increaseTextSize)
    package static let decreaseTextSize = ThemeImage(\.decreaseTextSize)
    package static let toggleDarkMode = ThemeImage(\.toggleDarkMode)
    package static let untoggleDarkMode = ThemeImage(\.untoggleDarkMode)
    package static let enterFullScreen = ThemeImage(\.enterFullScreen)
    package static let exitFullScreen = ThemeImage(\.exitFullScreen)
}

extension ThemeFont {
    package static let localePickerButton = ThemeFont(\.labelSmall)
}
