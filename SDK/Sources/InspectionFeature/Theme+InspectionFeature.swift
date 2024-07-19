// Theme+InspectionFeature.swift

import Theme

extension ModuleColors {
    var suggestionFieldBackground: ModuleColor { \.well }
    var placeholderBackground: ModuleColor { \.primary }
    var placeholderText: ModuleColor { \.onPrimary }
    var diffInsertion: ModuleColor { \.positive }
    var diffDeletion: ModuleColor { \.negative }
    var textPreviewToggle: ModuleColor { \.primary }
    var localePickerButtonBackground: ModuleColor { \.surface }
    var localePickerButtonBackgroundSelected: ModuleColor { \.primary }
    var localePickerButtonText: ModuleColor { \.foreground }
    var localePickerButtonTextSelected: ModuleColor { \.onPrimary }
}

extension ModuleFonts {
    var headerTitle: ModuleFont { \.headingMedium }
    var textPreviewHeading: ModuleFont { \.headingSmall }
    var textPreviewString: ModuleFont { \.bodySmall }
    var localizationDetails: ModuleFont { \.bodySmall }
    var localePickerButton: ModuleFont { \.labelSmall }
}
