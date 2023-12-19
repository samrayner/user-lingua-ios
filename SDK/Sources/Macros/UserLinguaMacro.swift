import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum UserLinguaMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration is StructDeclSyntax else {
            throw CustomError.message("@UserLingua can only be applied to structs.")
        }
        
        return [
            "@ObservedObject private (set) var userLinguaObservedObject = UserLingua.shared"
        ]
    }
}

private enum CustomError: Error, CustomStringConvertible {
    case message(String)
    
    var description: String {
        switch self {
        case .message(let text):
            return text
        }
    }
}

@main
struct UserLinguaPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        UserLinguaMacro.self,
    ]
}
