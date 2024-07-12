// Generated using Sourcery — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT


extension SelectionFeature.Dependencies {
    public init(from parent: Parent) {
        self.deviceOrientationObservable = parent.deviceOrientationObservable
        self.windowService = parent.windowService
        self.contentSizeCategoryService = parent.contentSizeCategoryService
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

