// Theme+InspectionFeature.swift

import Theme

extension ThemeColor {
    static let suggestionFieldBackground = ThemeColor(\.well)
    static let placeholderBackground = ThemeColor(\.primary)
    static let placeholderText = ThemeColor(\.onPrimary)
    static let localePickerButtonBackground = ThemeColor(\.surface)
    static let localePickerButtonBackgroundSelected = ThemeColor(\.primary)
    static let localePickerButtonText = ThemeColor(\.foreground)
    static let localePickerButtonTextSelected = ThemeColor(\.onPrimary)
    static let localizationDetailsBackground = ThemeColor(\.surfaceDim)
}

extension ThemeImage {
    static let increaseTextSize = ThemeImage(\.increaseTextSize)
    static let decreaseTextSize = ThemeImage(\.decreaseTextSize)
    static let toggleDarkMode = ThemeImage(\.toggleDarkMode)
    static let untoggleDarkMode = ThemeImage(\.untoggleDarkMode)
    static let enterFullScreen = ThemeImage(\.enterFullScreen)
    static let exitFullScreen = ThemeImage(\.exitFullScreen)
    static let doneSuggesting = ThemeImage(\.done)
    static let textualPreviewMode = ThemeImage(\.text)
    static let visualPreviewMode = ThemeImage(\.vision)
}

extension ThemeFont {
    static let localePickerButton = ThemeFont(\.labelSmall)
    static let textualPreviewHeading = ThemeFont(\.headingSmall)
    static let textualPreviewString = ThemeFont(\.bodySmall)
}
