import SwiftUI
import OverriddenSwiftUIMethods

extension Text {
    /// A UserLingua overload that forwards to`SwiftUI.Text(_:tableName:bundle:comment:)`.
    public init(
        _ key: LocalizedStringKey,
        tableName: String,
        bundle: Bundle,
        comment: StaticString,
        userLingua: Bool = UserLingua.shared.config.automaticallyOptInTextViews
    ) {
        let text = OverriddenSwiftUIMethods.Text.initWithKeyTableNameBundleComment(key, tableName, bundle, comment)
        self = if userLingua {
            UserLingua.shared.processLocalizedText(text)
        } else {
            text
        }
    }
    
    /// A UserLingua overload that forwards to`SwiftUI.Text(_:tableName:bundle:comment:)`.
    public init(
        _ key: LocalizedStringKey,
        tableName: String,
        bundle: Bundle,
        userLingua: Bool = UserLingua.shared.config.automaticallyOptInTextViews
    ) {
        let text = OverriddenSwiftUIMethods.Text.initWithKeyTableNameBundleComment(key, tableName, bundle, nil)
        self = if userLingua {
            UserLingua.shared.processLocalizedText(text)
        } else {
            text
        }
    }
    
    /// A UserLingua overload that forwards to`SwiftUI.Text(_:tableName:bundle:comment:)`.
    public init(
        _ key: LocalizedStringKey,
        tableName: String,
        userLingua: Bool = UserLingua.shared.config.automaticallyOptInTextViews
    ) {
        let text = OverriddenSwiftUIMethods.Text.initWithKeyTableNameBundleComment(key, tableName, .main, nil)
        self = if userLingua {
            UserLingua.shared.processLocalizedText(text)
        } else {
            text
        }
    }
    
    /// A UserLingua overload that forwards to`SwiftUI.Text(_:tableName:bundle:comment:)`.
    public init(
        _ key: LocalizedStringKey,
        userLingua: Bool = UserLingua.shared.config.automaticallyOptInTextViews
    ) {
        let text = OverriddenSwiftUIMethods.Text.initWithKeyTableNameBundleComment(key, "Localizable", .main, nil)
        self = if userLingua {
            UserLingua.shared.processLocalizedText(text)
        } else {
            text
        }
    }
    
    /// A UserLingua overload that forwards to`SwiftUI.Text(_ resource:)`.
    public init(
        localizedStringResource: LocalizedStringResource,
        userLingua: Bool = UserLingua.shared.config.automaticallyOptInTextViews
    ) {
        let text = Self.init(localizedStringResource)
        self = if userLingua {
            UserLingua.shared.processLocalizedText(text)
        } else {
            text
        }
    }
    
    /// A UserLingua overload that forwards to`SwiftUI.Text(_ string:)`.
    public init<S: StringProtocol>(
        _ content: S,
        userLingua: Bool = UserLingua.shared.config.automaticallyOptInTextViews
    ) {
        if UserLingua.shared.config.localizeStringWhenOnlyTextInitParam {
            self = .init(LocalizedStringKey(String(content)), userLingua: userLingua)
        } else {
            let string = userLingua ? Self.UL(content) : String(content)
            self = .init(verbatim: string)
        }
    }
}
