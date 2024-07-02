// Text+InitOverloads.swift

import Core
import SwiftUI
import SystemAPIAliases

extension Text {
    private init(_ formattedString: FormattedString) {
        UserLinguaClient.shared.record(formatted: formattedString)
        let displayString = UserLinguaClient.shared.displayString(for: formattedString)
        self = SystemText.initVerbatim(displayString)
    }

    // Note, private. Called by the overloads that use
    // non-optional parameters or fewer parameters to overload
    // the SwiftUI version of this initializer.
    private init(
        key: LocalizedStringKey,
        tableName: String? = nil,
        bundle: Bundle? = nil,
        comment: StaticString? = nil,
        userLingua: Bool = UserLinguaClient.shared.configuration.automaticallyOptInTextViews
    ) {
        guard userLingua, UserLinguaClient.shared.isEnabled else {
            self = SystemText.initTableNameBundleComment(key, tableName, bundle, comment)
            return
        }

        let formattedString = UserLinguaClient.shared.formattedString(
            localizedStringKey: key,
            tableName: tableName,
            bundle: bundle,
            comment: comment.map(\.description)
        )

        self.init(formattedString)
    }

    // Takes precedence over the SwiftUI version
    // due to fewer parameters. Used for Text("this").
    public init(
        _ key: LocalizedStringKey,
        tableName: String? = nil,
        userLingua: Bool = UserLinguaClient.shared.configuration.automaticallyOptInTextViews
    ) {
        self.init(
            key: key,
            tableName: tableName,
            bundle: nil,
            comment: nil,
            userLingua: userLingua
        )
    }

    // Takes precedence over the SwiftUI version
    // due to fewer parameters. Avoids ambiguity
    // by making bundle non-optional.
    public init(
        _ key: LocalizedStringKey,
        bundle: Bundle,
        userLingua: Bool = UserLinguaClient.shared.configuration.automaticallyOptInTextViews
    ) {
        self.init(
            key: key,
            tableName: nil,
            bundle: bundle,
            comment: nil,
            userLingua: userLingua
        )
    }

    // Takes precedence over the SwiftUI version
    // due to fewer parameters. Avoids ambiguity
    // by making comment non-optional.
    public init(
        _ key: LocalizedStringKey,
        comment: StaticString,
        userLingua: Bool = UserLinguaClient.shared.configuration.automaticallyOptInTextViews
    ) {
        self.init(
            key: key,
            tableName: nil,
            bundle: nil,
            comment: comment,
            userLingua: userLingua
        )
    }

    // Takes precedence over the SwiftUI version
    // due to the non-optional bundle and comment types.
    public init(
        _ key: LocalizedStringKey,
        bundle: Bundle,
        comment: StaticString,
        userLingua: Bool = UserLinguaClient.shared.configuration.automaticallyOptInTextViews
    ) {
        self.init(
            key: key,
            tableName: nil,
            bundle: bundle,
            comment: comment,
            userLingua: userLingua
        )
    }

    // Takes precedence over the SwiftUI version
    // due to the non-optional tableName type.
    public init(
        _ key: LocalizedStringKey,
        tableName: String,
        bundle: Bundle? = nil,
        userLingua: Bool = UserLinguaClient.shared.configuration.automaticallyOptInTextViews
    ) {
        self.init(
            key: key,
            tableName: tableName,
            bundle: bundle,
            comment: nil,
            userLingua: userLingua
        )
    }

    // Takes precedence over the SwiftUI version
    // due to the non-optional parameter types.
    public init(
        _ key: LocalizedStringKey,
        tableName: String,
        bundle: Bundle,
        comment: StaticString? = nil,
        userLingua: Bool = UserLinguaClient.shared.configuration.automaticallyOptInTextViews
    ) {
        self.init(
            key: key,
            tableName: tableName,
            bundle: bundle,
            comment: comment,
            userLingua: userLingua
        )
    }

    // Unfortunately we can't overload this with an anonymous
    // first parameter as it is ambiguous.
    public init(
        localizedStringResource: LocalizedStringResource,
        userLingua: Bool = UserLinguaClient.shared.configuration.automaticallyOptInTextViews
    ) {
        guard userLingua, UserLinguaClient.shared.isEnabled else {
            self = SystemText.initLocalizedStringResource(localizedStringResource)
            return
        }

        self.init(
            FormattedString(
                LocalizedString(
                    localizedStringResource.key,
                    tableName: localizedStringResource.table,
                    bundle: localizedStringResource.bundle,
                    comment: nil
                )
            )
        )
    }

    // Takes precedence over SwiftUI's
    // @_disfavoredOverload init<S: StringProtocol>(_ content: S)
    // due to the concrete content type giving higher specificity
    // than the generic content type.
    // Doesn't take precedence for init("a string literal")
    // thanks to @_disfavoredOverload. Instead that will call
    // init(LocalizedStringKey, ...) as LocalizedStringKey conforms
    // to ExpressibleByStringLiteral. This matches the
    // behaviour of SwiftUI's Text init methods.
    @_disfavoredOverload
    public init(
        _ content: String,
        userLingua: Bool = UserLinguaClient.shared.configuration.automaticallyOptInTextViews
    ) {
        guard userLingua, UserLinguaClient.shared.isEnabled else {
            self = SystemText.initVerbatim(content)
            return
        }

        let string = UserLinguaClient.shared.processString(content)

        self = SystemText.initVerbatim(string)
    }

    // Takes precedence over SwiftUI's
    // @_disfavoredOverload init<S: StringProtocol>(_ content: S)
    // due to the concrete content type giving higher specificity
    // than the generic content type.
    // Doesn't take precedence for init("a string literal")
    // thanks to @_disfavoredOverload. Instead that will call
    // init(LocalizedStringKey, ...) as LocalizedStringKey conforms
    // to ExpressibleByStringLiteral. This matches the
    // behaviour of SwiftUI's Text init methods.
    @_disfavoredOverload
    public init(
        _ content: Substring,
        userLingua: Bool = UserLinguaClient.shared.configuration.automaticallyOptInTextViews
    ) {
        self.init(String(content), userLingua: userLingua)
    }
}
