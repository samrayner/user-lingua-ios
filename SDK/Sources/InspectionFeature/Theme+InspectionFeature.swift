// Theme+InspectionFeature.swift

import Theme

extension ThemeColor {
    static let suggestionFieldBackground = ThemeColor(\.well)
    static let placeholderBackground = ThemeColor(\.primary)
    static let placeholderText = ThemeColor(\.onPrimary)
    static let localePickerSelectionIndicator = ThemeColor(\.primary)
    static let localePickerButtonBackground = ThemeColor(\.surface)
}

extension ThemeImage {
    static let increaseTextSize = ThemeImage(\.increaseTextSize)
    static let decreaseTextSize = ThemeImage(\.decreaseTextSize)
    static let toggleDarkMode = ThemeImage(\.toggleDarkMode)
    static let untoggleDarkMode = ThemeImage(\.untoggleDarkMode)
    static let enterFullScreen = ThemeImage(\.expandDiagonally)
    static let exitFullScreen = ThemeImage(\.contractDiagonally)
    static let doneSuggesting = ThemeImage(\.chevronDown)
    static let textualPreviewMode = ThemeImage(\.paragraph)
    static let visualPreviewMode = ThemeImage(\.eye)
}

extension ThemeFont {
    static let headerTitle = ThemeFont(\.headingMedium)
    static let textualPreviewHeading = ThemeFont(\.headingSmall)
    static let textualPreviewString = ThemeFont(\.bodySmall)
    static let localizationDetails = ThemeFont(\.bodySmall)
}
