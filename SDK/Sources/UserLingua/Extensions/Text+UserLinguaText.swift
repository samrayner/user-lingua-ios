import SwiftUI

public protocol UserLinguaText {
    init(_ text: Text)
}

extension Text {
    public init(_ text: Text) {
        self = text
    }
    
    public func userLingua(dsoHandle: UnsafeRawPointer = #dsohandle) -> Text {
        if self is UserLinguaText {
            self
        } else {
            UserLingua.shared.processText(self, bundle: .init(dsoHandle: dsoHandle))
        }
    }
}

extension UserLinguaText {
    /// A UserLingua overload that forwards to`SwiftUI.Text(_:tableName:bundle:comment:)`.
    public init(
        _ key: LocalizedStringKey,
        tableName: String,
        bundle: Bundle,
        comment: StaticString,
        userLingua: Bool = UserLingua.shared.config.automaticallyOptInTextViews
    ) {
        let text = Text(key, tableName: tableName, bundle: bundle, comment: comment)
        self.init(userLingua ? UserLingua.shared.processText(text) : text)
    }
    
    /// A UserLingua overload that forwards to`SwiftUI.Text(_:tableName:bundle:comment:)`.
    public init(
        _ key: LocalizedStringKey,
        tableName: String,
        bundle: Bundle,
        userLingua: Bool = UserLingua.shared.config.automaticallyOptInTextViews
    ) {
        let text = Text(key, tableName: tableName, bundle: bundle)
        self.init(userLingua ? UserLingua.shared.processText(text) : text)
    }
    
    /// A UserLingua overload that forwards to`SwiftUI.Text(_:tableName:bundle:comment:)`.
    public init(
        _ key: LocalizedStringKey,
        tableName: String,
        userLingua: Bool = UserLingua.shared.config.automaticallyOptInTextViews,
        dsoHandle: UnsafeRawPointer = #dsohandle
    ) {
        let text = Text(key, tableName: tableName, bundle: .init(dsoHandle: dsoHandle))
        self.init(userLingua ? UserLingua.shared.processText(text) : text)
    }
    
    /// A UserLingua overload that forwards to`SwiftUI.Text(_:tableName:bundle:comment:)`.
    public init(
        _ key: LocalizedStringKey,
        userLingua: Bool = UserLingua.shared.config.automaticallyOptInTextViews,
        dsoHandle: UnsafeRawPointer = #dsohandle
    ) {
        let text = Text(key, bundle: .init(dsoHandle: dsoHandle))
        self.init(userLingua ? UserLingua.shared.processText(text) : text)
    }
    
    /// A UserLingua overload that forwards to`SwiftUI.Text(_ resource:)`.
    public init(
        localizedStringResource: LocalizedStringResource,
        userLingua: Bool = UserLingua.shared.config.automaticallyOptInTextViews
    ) {
        let text = Text(localizedStringResource)
        self.init(userLingua ? UserLingua.shared.processText(text) : text)
    }
    
    /// A UserLingua overload that forwards to`SwiftUI.Text(_ string:)`.
    public init<S: StringProtocol>(
        _ content: S,
        userLingua: Bool = UserLingua.shared.config.automaticallyOptInTextViews,
        dsoHandle: UnsafeRawPointer = #dsohandle
    ) {
        let text = Text(content)
        self.init(userLingua ? UserLingua.shared.processText(text, bundle: .init(dsoHandle: dsoHandle)) : text)
    }
}
