// Theme+InspectionFeature.swift

import Theme

extension ModuleColors {
    var suggestionFieldBackground: ModuleColor { \.well }
    var placeholderBackground: ModuleColor { \.primary }
    var placeholderText: ModuleColor { \.onPrimary }
    var localePickerSelectionIndicator: ModuleColor { \.primary }
    var localePickerButtonBackground: ModuleColor { \.surface }
}

extension ModuleFonts {
    var headerTitle: ModuleFont { \.headingMedium }
    var textualPreviewHeading: ModuleFont { \.headingSmall }
    var textualPreviewString: ModuleFont { \.bodySmall }
    var localizationDetails: ModuleFont { \.bodySmall }
}
