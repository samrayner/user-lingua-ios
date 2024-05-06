// Theme+InspectionFeature.swift

import Theme

extension ModuleColors {
    var suggestionFieldBackground: ModuleColor { \.well }
    var placeholderBackground: ModuleColor { \.primary }
    var placeholderText: ModuleColor { \.onPrimary }
    var localePickerSelectionIndicator: ModuleColor { \.primary }
    var localePickerButtonBackground: ModuleColor { \.surface }
    var diffInsertion: ModuleColor { \.positive }
    var diffDeletion: ModuleColor { \.negative }
    var textPreviewToggle: ModuleColor { \.primary }
}

extension ModuleFonts {
    var headerTitle: ModuleFont { \.headingMedium }
    var textPreviewHeading: ModuleFont { \.headingSmall }
    var textPreviewString: ModuleFont { \.bodySmall }
    var localizationDetails: ModuleFont { \.bodySmall }
}
