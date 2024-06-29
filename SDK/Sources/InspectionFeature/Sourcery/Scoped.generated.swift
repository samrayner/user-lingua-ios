// Generated using Sourcery — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT


extension AppPreviewFeatureView.BodyState {
    init(parent: Parent) {
        self.isFullScreen = parent.isFullScreen
        self.appIsInDarkMode = parent.appIsInDarkMode
    }
}

extension InspectionFeatureView.BodyState {
    init(parent: Parent) {
        self.isFullScreen = parent.isFullScreen
        self.previewMode = parent.previewMode
    }
}

extension InspectionFeatureView.InspectionPanelState {
    init(parent: Parent) {
        self.suggestionValue = parent.suggestionValue
        self.localizedValue = parent.localizedValue
        self.recognizedString = parent.recognizedString
        self.locale = parent.locale
        self.keyboardHeight = parent.keyboardHeight
        self.focusedField = parent.focusedField
    }
}

extension InspectionFeatureView.ViewportState {
    init(parent: Parent) {
        self.isFullScreen = parent.isFullScreen
        self.isTransitioning = parent.isTransitioning
    }
}

extension TextPreviewFeatureView.BodyState {
    init(parent: Parent) {
        self.locale = parent.locale
        self.diff = parent.diff
        self.suggestionValue = parent.suggestionValue
    }
}

