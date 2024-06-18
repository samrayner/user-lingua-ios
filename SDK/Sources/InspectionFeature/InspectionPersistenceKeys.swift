// InspectionPersistenceKeys.swift

import ComposableArchitecture

extension PersistenceKey where Self == AppStorageKey<InspectionFeature.State.PreviewMode> {
    static var previewMode: Self { appStorage("com.userLingua.\(#function)") }
}

extension PersistenceKey where Self == AppStorageKey<Bool> {
    static var textPreviewBaseIsExpanded: Self { appStorage("com.userLingua.\(#function)") }
    static var textPreviewOriginalIsExpanded: Self { appStorage("com.userLingua.\(#function)") }
    static var textPreviewSuggestionIsExpanded: Self { appStorage("com.userLingua.\(#function)") }
    static var textPreviewDiffIsExpanded: Self { appStorage("com.userLingua.\(#function)") }
}
