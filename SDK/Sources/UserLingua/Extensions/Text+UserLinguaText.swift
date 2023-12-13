import SwiftUI
import SystemAPIAliases

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
    private init(_ localizedString: LocalizedString) {
        if UserLingua.shared.state == .recordingStrings {
            UserLingua.shared.db.record(localizedString: localizedString)
        }
        let displayString = UserLingua.shared.displayString(for: localizedString)
        self.init(SystemText.initVerbatim(displayString))
    }
    
    /// A UserLingua overload that forwards to`SwiftUI.Text(_:tableName:bundle:comment:)`.
    public init(
        _ key: LocalizedStringKey,
        tableName: String? = nil,
        bundle: Bundle? = nil,
        comment: StaticString = "",
        userLingua: Bool = true
    ) {
        guard userLingua, UserLingua.shared.state != .disabled else {
            self.init(SystemText.initTableNameBundleComment(key, tableName, bundle, comment))
            return
        }
        
        self.init(
            LocalizedString(
                key,
                tableName: tableName,
                bundle: bundle,
                comment: comment
            )
        )
    }
    
    /// A UserLingua overload that forwards to`SwiftUI.Text(_ resource:)`.
    public init(
        localizedStringResource: LocalizedStringResource,
        userLingua: Bool = true
    ) {
        guard userLingua, UserLingua.shared.state != .disabled else {
            self.init(SystemText.initLocalizedStringResource(localizedStringResource))
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
        userLingua: Bool = true
    ) {
        let content = String(content)
        
        guard userLingua, UserLingua.shared.state != .disabled else {
            self.init(SystemText.initVerbatim(content))
            return
        }
        
        let string = UserLingua.shared.processString(
            content,
            localize: UserLingua.shared.config.localizeStringWhenOnlyParamOfTextInit
        )
        
        self.init(SystemText.initVerbatim(string))
    }
}
