import SwiftUI

public protocol UserLinguaText {
    init(_ text: Text)
}

extension Text {
    public init(_ text: Text) {
        self = text
    }
    
    public func userLingua() -> Text {
        if self is UserLinguaText {
            self
        } else {
            UserLingua.shared.processText(self)
        }
    }
}

extension UserLinguaText {
    /// A UserLingua overload that forwards to`SwiftUI.Text(_:tableName:bundle:comment:)`.
    public init(
        _ key: LocalizedStringKey,
        tableName: String? = nil,
        bundle: Bundle = .main,
        comment: StaticString? = nil,
        userLingua: Bool = true
    ) {
        let text = Text(key, tableName: tableName, bundle: bundle, comment: comment)
        self.init(userLingua ? UserLingua.shared.processText(text) : text)
    }
    
    /// A UserLingua overload that forwards to`SwiftUI.Text(_ resource:)`.
    public init(
        localizedStringResource: LocalizedStringResource,
        userLingua: Bool = true
    ) {
        let text = Text(localizedStringResource)
        self.init(userLingua ? UserLingua.shared.processText(text) : text)
    }
    
    /// A UserLingua overload that forwards to`SwiftUI.Text(_ string:)`.
    public init<S: StringProtocol>(
        _ content: S,
        userLingua: Bool = true
    ) {
        let text = Text(content)
        self.init(userLingua ? UserLingua.shared.processText(text) : text)
    }
}
