// UserLinguaMacro.swift

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum UserLinguaMacro: MemberMacro {
    public static func expansion(
        of _: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in _: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration is StructDeclSyntax else {
            throw CustomError.message("@UserLingua can only be applied to structs.")
        }

        return [
            "@ObservedObject private (set) var _userLinguaObservedObject = UserLingua.shared.observableObject"
        ]
    }
}

private enum CustomError: Error, CustomStringConvertible {
    case message(String)

    var description: String {
        switch self {
        case let .message(text):
            text
        }
    }
}

@main
struct UserLinguaPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        UserLinguaMacro.self
    ]
}
