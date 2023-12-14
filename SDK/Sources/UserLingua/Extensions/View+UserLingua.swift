import SwiftUI

extension View {
    @ViewBuilder public func userLinguaDisabled() -> some View {
        self.redacted(
            reason: UserLingua.shared.state == .detectingStrings ? .placeholder : []
        )
    }
    
    /// Allows suggestions for the given string using UserLingua.
    ///
    /// For Text views, consider `import UserLinguaTextOptIn` instead.
    ///
    /// Use this method to look for the `key` parameter in a localization
    /// table and display the associated string value in the
    /// view. If the method can't find the key in the table, or if no table
    /// exists, the view displays the string representation of the key
    /// instead.
    ///
    ///     UL("pencil") // Localizes the key if possible, or displays "pencil" if not.
    ///
    /// When you pass in a string literal, the view triggers
    /// this method because it assumes you want the string localized. If
    /// you haven't provided localization for a particular string, you still get
    /// reasonable behavior, because the initializer displays the key, which
    /// typically contains the unlocalized string.
    ///
    /// If you pass in a string variable rather than a
    /// string literal, the view triggers `UL<S: StringProtocol>(_: S)`
    /// instead, because it assumes that you don't want localization
    /// in that case. If you do want to localize the value stored in a string
    /// variable, you can first create a ``LocalizedStringKey`` instance from the
    /// string variable:
    ///
    ///     UL(LocalizedStringKey(someString)) // Localizes the contents of `someString`.
    ///
    /// If you have a string literal that you don't want to localize, use
    /// `UL(verbatim:)` instead.
    public func UL(_ key: LocalizedStringKey) -> String {
        UserLingua.shared.processLocalizedStringKey(key)
    }
    
    /// Allows suggestions for the given string using UserLingua without localization.
    ///
    ///     UL(verbatim: "pencil") // Displays the string "pencil" in any locale.
    ///
    /// If you want to localize a string literal before displaying it, use
    /// `UL(_: LocalizedStringKey)` instead. If you
    /// want to display a string variable, use `UL<S: StringProtocol>(_: S)`
    /// which also bypasses localization.
    public func UL(verbatim string: String) -> String {
        UserLingua.shared.processString(string)
    }
    
    /// Allows suggestions for the given string using UserLingua without localization.
    ///
    ///     Text(someString) // Displays the contents of `someString` without localization.
    ///
    /// SwiftUI doesn't call this method when you pass
    /// a string literal as the input. Instead, a string literal
    /// triggers the `UL(LocalizedStringKey)` method which attempts to
    /// perform localization.
    ///
    /// By default, SwiftUI assumes that you don't want to localize stored
    /// strings, but if you do, you can first create a localized string key from
    /// the value, and pass that in. Using a key as input
    /// triggers `UL(LocalizedStringKey)` instead.
    @_disfavoredOverload public func UL<S: StringProtocol>(_ string: S) -> String {
        UL(verbatim: String(string))
    }
}
