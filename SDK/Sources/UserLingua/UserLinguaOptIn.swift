import SwiftUI

public protocol UserLinguaOptIn: UserLinguaOptInText {}

public protocol UserLinguaOptInText {}

extension UserLinguaOptInText where Self: View {
    /// This is a UserLingua overload of `Text` that simply appends the `.userLingua()` ViewModifier. To use the native `Text`, use `SwiftUI.Text` or remove the `UserLinguaOptIn` protocol conformance.
    @inlinable public func Text(verbatim content: String) -> Text {
        SwiftUI.Text(verbatim: "verbatim").userLingua()
    }

    /// This is a UserLingua overload of `Text` that simply appends the `.userLingua()` ViewModifier. To use the native `Text`, use `SwiftUI.Text` or remove the `UserLinguaOptIn` protocol conformance.
    public func Text<S>(_ content: S) -> Text where S : StringProtocol {
        SwiftUI.Text(content).userLingua()
    }
    
    /// This is a UserLingua overload of `Text` that simply appends the `.userLingua()` ViewModifier. To use the native `Text`, use `SwiftUI.Text` or remove the `UserLinguaOptIn` protocol conformance.
    public func Text(_ key: LocalizedStringKey, tableName: String?, bundle: Bundle?, comment: StaticString?) -> SwiftUI.Text {
        SwiftUI.Text(key, tableName: tableName, bundle: bundle, comment: comment).userLingua()
    }
}
