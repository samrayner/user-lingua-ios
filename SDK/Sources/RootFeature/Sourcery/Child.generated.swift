// Generated using Sourcery — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT


extension RootFeature.Dependencies {
    public init(from parent: Parent) {
        self.notificationCenter = parent.notificationCenter
        self.windowService = parent.windowService
        self.swizzler = parent.swizzler
        self.selection = .init(from: parent)
    }
}

