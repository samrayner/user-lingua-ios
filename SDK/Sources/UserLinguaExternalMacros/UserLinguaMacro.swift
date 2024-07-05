// UserLinguaMacro.swift

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum CopyEditableMacro: MemberMacro {
    public static func expansion(
        of _: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in _: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration is StructDeclSyntax else {
            throw CustomError.message("@CopyEditable should only be applied to SwiftUI Views.")
        }

        return [
            "@ObservedObject private (set) var _userLinguaViewModel = UserLinguaClient.shared.viewModel"
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
        CopyEditableMacro.self
    ]
}
