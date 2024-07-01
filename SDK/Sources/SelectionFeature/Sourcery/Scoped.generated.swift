// Generated using Sourcery — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT


extension SelectionFeature.Dependencies {
    package init(from parent: Parent) {
        self.windowService = parent.windowService
        self.contentSizeCategoryService = parent.contentSizeCategoryService
        self.orientationService = parent.orientationService
        self.inspection = .init(from: parent)
        self.recognition = .init(from: parent)
    }
}

extension SelectionFeatureView.BodyState {
    internal init(from parent: Parent) {
        self.recognizedStrings = parent.recognizedStrings
        self.isInspecting = parent.isInspecting
    }
}

