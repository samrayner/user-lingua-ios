// InspectionPersistenceKeys.swift

import CombineFeedback

extension AppStorageKey where Value == InspectionFeature.State.PreviewMode {
    static var previewMode: Self { .init("com.userLingua.\(#function)") }
}

extension AppStorageKey where Value == Bool {
    static var textPreviewBaseIsExpanded: Self { .init("com.userLingua.\(#function)") }
    static var textPreviewOriginalIsExpanded: Self { .init("com.userLingua.\(#function)") }
    static var textPreviewSuggestionIsExpanded: Self { .init("com.userLingua.\(#function)") }
    static var textPreviewDiffIsExpanded: Self { .init("com.userLingua.\(#function)") }
}
