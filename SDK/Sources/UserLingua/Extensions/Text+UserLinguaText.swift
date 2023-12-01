import SwiftUI

public protocol UserLinguaText {
    init(_ text: Text)
}

extension Text {
    public init(_ text: Text) {
        self = text
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
        let originalText = Text(key, tableName: tableName, bundle: bundle, comment: comment)
        let text = if userLingua {
            UserLingua.shared.processLocalizedText(originalText)
        } else {
            originalText
        }
        self.init(text)
    }
    
    /// A UserLingua overload that forwards to`SwiftUI.Text(_:tableName:bundle:comment:)`.
    public init(
        _ key: LocalizedStringKey,
        tableName: String,
        bundle: Bundle,
        userLingua: Bool = UserLingua.shared.config.automaticallyOptInTextViews
    ) {
        let originalText = Text(key, tableName: tableName, bundle: bundle)
        let text = if userLingua {
            UserLingua.shared.processLocalizedText(originalText)
        } else {
            originalText
        }
        self.init(text)
    }
    
    /// A UserLingua overload that forwards to`SwiftUI.Text(_:tableName:bundle:comment:)`.
    public init(
        _ key: LocalizedStringKey,
        tableName: String,
        userLingua: Bool = UserLingua.shared.config.automaticallyOptInTextViews
    ) {
        let originalText = Text(key, tableName: tableName)
        let text = if userLingua {
            UserLingua.shared.processLocalizedText(originalText)
        } else {
            originalText
        }
        self.init(text)
    }
    
    /// A UserLingua overload that forwards to`SwiftUI.Text(_:tableName:bundle:comment:)`.
    public init(
        _ key: LocalizedStringKey,
        userLingua: Bool = UserLingua.shared.config.automaticallyOptInTextViews
    ) {
        let originalText = Text(key)
        let text = if userLingua {
            UserLingua.shared.processLocalizedText(originalText)
        } else {
            originalText
        }
        self.init(text)
    }
    
    /// A UserLingua overload that forwards to`SwiftUI.Text(_ resource:)`.
    public init(
        localizedStringResource: LocalizedStringResource,
        userLingua: Bool = UserLingua.shared.config.automaticallyOptInTextViews
    ) {
        let originalText = Text(localizedStringResource)
        let text = if userLingua {
            UserLingua.shared.processLocalizedText(originalText)
        } else {
            originalText
        }
        self.init(text)
    }
    
    /// A UserLingua overload that forwards to`SwiftUI.Text(_ string:)`.
    public init<S: StringProtocol>(
        _ content: S,
        userLingua: Bool = UserLingua.shared.config.automaticallyOptInTextViews
    ) {
        let string = if userLingua {
            Text.UL(content, localize:  UserLingua.shared.config.localizeStringWhenOnlyParamOfTextInit)
        } else {
            String(content)
        }
        self.init(Text(string))
    }
}
