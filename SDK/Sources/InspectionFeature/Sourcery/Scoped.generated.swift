// Generated using Sourcery — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT


extension AppPreviewFeatureView.BodyState {
    internal init(from parent: Parent) {
        self.isFullScreen = parent.isFullScreen
        self.appIsInDarkMode = parent.appIsInDarkMode
    }
}

extension InspectionFeature.Dependencies {
    package init(from parent: Parent) {
        self.notificationCenter = parent.notificationCenter
        self.windowService = parent.windowService
        self.appViewModel = parent.appViewModel
        self.contentSizeCategoryService = parent.contentSizeCategoryService
        self.orientationService = parent.orientationService
        self.suggestionsRepository = parent.suggestionsRepository
        self.recognition = .init(from: parent)
    }
}

extension InspectionFeatureView.BodyState {
    internal init(from parent: Parent) {
        self.isFullScreen = parent.isFullScreen
        self.keyboardHeight = parent.keyboardHeight
        self.keyboardAnimation = parent.keyboardAnimation
        self.previewMode = parent.previewMode
    }
}

extension InspectionFeatureView.InspectionPanelState {
    internal init(from parent: Parent) {
        self.suggestionValue = parent.suggestionValue
        self.localizedValue = parent.localizedValue
        self.recognizedString = parent.recognizedString
        self.locale = parent.locale
        self.keyboardHeight = parent.keyboardHeight
        self.focusedField = parent.focusedField
    }
}

extension InspectionFeatureView.ViewportState {
    internal init(from parent: Parent) {
        self.isFullScreen = parent.isFullScreen
        self.isTransitioning = parent.isTransitioning
    }
}

extension TextPreviewFeatureView.BodyState {
    internal init(from parent: Parent) {
        self.locale = parent.locale
        self.diff = parent.diff
        self.suggestionValue = parent.suggestionValue
    }
}

