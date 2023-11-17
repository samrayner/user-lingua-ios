import SwiftUI
import OverriddenSwiftUIMethods

extension Text {
    /// A UserLingua overload that forwards to`SwiftUI.Text(_:tableName:bundle:comment:)`.
    public init(
        _ key: LocalizedStringKey,
        tableName: String,
        bundle: Bundle,
        comment: StaticString,
        userLingua: Bool = UserLingua.shared.config.automaticallyOptInLocalizedTextViews
    ) {
        let text = OverriddenSwiftUIMethods.initKeyTableNameBundleComment(key, tableName, bundle, comment)
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
        userLingua: Bool = UserLingua.shared.config.automaticallyOptInLocalizedTextViews
    ) {
        let text = OverriddenSwiftUIMethods.initKeyTableNameBundleComment(key, tableName, bundle, nil)
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
        userLingua: Bool = UserLingua.shared.config.automaticallyOptInLocalizedTextViews
    ) {
        let text = OverriddenSwiftUIMethods.initKeyTableNameBundleComment(key, tableName, .main, nil)
        self = if userLingua {
            UserLingua.shared.processLocalizedText(text)
        } else {
            text
        }
    }
    
    /// A UserLingua overload that forwards to`SwiftUI.Text(_:tableName:bundle:comment:)`.
    public init(
        _ key: LocalizedStringKey,
        userLingua: Bool = UserLingua.shared.config.automaticallyOptInLocalizedTextViews
    ) {
        let text = OverriddenSwiftUIMethods.initKeyTableNameBundleComment(key, "Localizable", .main, nil)
        self = if userLingua {
            UserLingua.shared.processLocalizedText(text)
        } else {
            text
        }
    }
    
    /// A UserLingua overload that forwards to`SwiftUI.Text(_:)`.
    public init(
        localizedStringResource: LocalizedStringResource,
        userLingua: Bool = UserLingua.shared.config.automaticallyOptInLocalizedTextViews
    ) {
        let text = OverriddenSwiftUIMethods.initLocalizedStringResource(localizedStringResource)
        self = if userLingua {
            UserLingua.shared.processLocalizedText(text)
        } else {
            text
        }
    }
}
