import SwiftUI
import SystemAPIAliases

extension Text {
    public func userLingua() -> Text {
        UserLingua.shared.processText(self)
    }
    
    private init(_ localizedString: LocalizedString) {
        if UserLingua.shared.state == .recordingStrings {
            UserLingua.shared.db.record(localizedString: localizedString)
        }
        let displayString = UserLingua.shared.displayString(for: localizedString)
        self = SystemText.initVerbatim(displayString)
    }
    
    /// A UserLingua overload that forwards to`SwiftUI.Text(_:tableName:bundle:comment:)`.
    public init(
        key: LocalizedStringKey,
        tableName: String? = nil,
        bundle: Bundle? = nil,
        comment: StaticString? = nil,
        userLingua: Bool = UserLingua.shared.config.automaticallyOptInTextViews
    ) {        
        guard userLingua, 
              UserLingua.shared.state != .disabled,
              let localizedString = UserLingua.shared.localizedString(
                  localizedStringKey: key,
                  tableName: tableName,
                  bundle: bundle,
                  comment: String(describing: comment)
              )
        else {
            self = SystemText.initTableNameBundleComment(key, tableName, bundle, comment)
            return
        }
        
        self.init(localizedString)
    }
    
    /// A UserLingua overload that forwards to`SwiftUI.Text(_:tableName:bundle:comment:)`.
    public init(
        _ key: LocalizedStringKey,
        tableName: String? = nil,
        userLingua: Bool = UserLingua.shared.config.automaticallyOptInTextViews
    ) {
        self.init(
            key: key,
            tableName: tableName,
            bundle: nil,
            comment: nil,
            userLingua: userLingua
        )
    }
    
    /// A UserLingua overload that forwards to`SwiftUI.Text(_:tableName:bundle:comment:)`.
    public init(
        _ key: LocalizedStringKey,
        tableName: String,
        bundle: Bundle? = nil,
        userLingua: Bool = UserLingua.shared.config.automaticallyOptInTextViews
    ) {
        self.init(
            key: key,
            tableName: tableName,
            bundle: bundle,
            comment: nil,
            userLingua: userLingua
        )
    }
    
    /// A UserLingua overload that forwards to`SwiftUI.Text(_:tableName:bundle:comment:)`.
    public init(
        _ key: LocalizedStringKey,
        tableName: String,
        bundle: Bundle,
        comment: StaticString? = nil,
        userLingua: Bool = UserLingua.shared.config.automaticallyOptInTextViews
    ) {
        self.init(
            key: key,
            tableName: tableName,
            bundle: bundle,
            comment: comment,
            userLingua: userLingua
        )
    }
    
    /// A UserLingua overload that forwards to`SwiftUI.Text(_ resource:)`.
    public init(
        localizedStringResource: LocalizedStringResource,
        userLingua: Bool = UserLingua.shared.config.automaticallyOptInTextViews
    ) {
        guard userLingua, UserLingua.shared.state != .disabled else {
            self = SystemText.initLocalizedStringResource(localizedStringResource)
            return
        }
        
        self.init(
            LocalizedString(
                localizedStringResource.key,
                tableName: localizedStringResource.table,
                bundle: localizedStringResource.bundle,
                comment: nil
            )
        )
    }
    
    /// A UserLingua overload that forwards to`SwiftUI.Text(_ string:)`.
    public init<S: StringProtocol>(
        _ content: S,
        userLingua: Bool = UserLingua.shared.config.automaticallyOptInTextViews
    ) {
        let content = String(content)
        
        guard userLingua, UserLingua.shared.state != .disabled else {
            self = SystemText.initVerbatim(content)
            return
        }
        
        let string = UserLingua.shared.processString(
            content,
            localize: UserLingua.shared.config.localizeStringWhenOnlyParamOfTextInit
        )
        
        self = SystemText.initVerbatim(string)
    }
}
