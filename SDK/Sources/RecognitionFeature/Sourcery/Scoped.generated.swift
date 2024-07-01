// Generated using Sourcery — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT


extension RecognitionFeature.Dependencies {
    package init(from parent: Parent) {
        self.windowService = parent.windowService
        self.appViewModel = parent.appViewModel
        self.stringRecognizer = parent.stringRecognizer
    }
}

