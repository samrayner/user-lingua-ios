// ViewActionMacro.swift

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

public struct ViewActionMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo _: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard
            case let .argumentList(arguments) = node.arguments,
            arguments.count == 1,
            let memberAccessExpr = arguments.first?.expression.as(MemberAccessExprSyntax.self)
        else { return [] }
        let inputType = String("\(memberAccessExpr)".dropLast(5))

        guard declaration.hasStoreVariable
        else {
            var declarationWithStoreVariable = declaration
            declarationWithStoreVariable.memberBlock.members.insert(
                MemberBlockItemSyntax(
                    leadingTrivia: declarationWithStoreVariable.memberBlock.members.first?.leadingTrivia
                        ?? "\n    ",
                    decl: VariableDeclSyntax(
                        bindingSpecifier: declaration.modifiers.bindingSpecifier(),
                        bindings: [
                            PatternBindingSyntax(
                                pattern: " store" as PatternSyntax,
                                typeAnnotation: TypeAnnotationSyntax(
                                    type: " StoreOf<\(raw: inputType)>" as TypeSyntax
                                )
                            )
                        ]
                    ),
                    trailingTrivia: .newline
                ),
                at: declarationWithStoreVariable.memberBlock.members.startIndex
            )

            context.diagnose(
                Diagnostic(
                    node: declaration,
                    message: MacroExpansionErrorMessage(
                        """
                        '@ViewAction' requires \
                        \(declaration.identifierDescription.map { "'\($0)' " } ?? " ")to have a 'store' \
                        property of type 'Store'.
                        """
                    ),
                    fixIt: .replace(
                        message: MacroExpansionFixItMessage("Add 'store'"),
                        oldNode: declaration,
                        newNode: declarationWithStoreVariable
                    )
                )
            )
            return []
        }

        declaration.diagnoseDirectStoreDotSend(
            declaration: declaration,
            context: context
        )

        let ext: DeclSyntax =
            """
            \(declaration.attributes.availability)extension \(type.trimmed): \
            ComposableArchitecture.ViewActionSending {}
            """
        return [ext.cast(ExtensionDeclSyntax.self)]
    }
}

extension SyntaxProtocol {
    func diagnoseDirectStoreDotSend(
        declaration: some SyntaxProtocol,
        context: some MacroExpansionContext
    ) {
        for decl in declaration.children(viewMode: .fixedUp) {
            if let functionCall = decl.as(FunctionCallExprSyntax.self) {
                if let sendExpression = functionCall.sendExpression {
                    var fixIt: FixIt?
                    if let outer = functionCall.arguments.first,
                       let inner = outer.expression.as(FunctionCallExprSyntax.self),
                       inner.calledExpression
                       .as(MemberAccessExprSyntax.self)?.declName.baseName.text == "view",
                       inner.arguments.count == 1 {
                        var newFunctionCall = functionCall
                        newFunctionCall.calledExpression = sendExpression
                        newFunctionCall.arguments = inner.arguments
                        fixIt = .replace(
                            message: MacroExpansionFixItMessage("Call 'send' directly with a view action"),
                            oldNode: functionCall,
                            newNode: newFunctionCall
                        )
                    }
                    context.diagnose(
                        Diagnostic(
                            node: decl,
                            message: MacroExpansionWarningMessage(
                                """
                                Do not use 'store.send' directly when using '@ViewAction'
                                """
                            ),
                            highlights: [decl],
                            fixIts: fixIt.map { [$0] } ?? []
                        )
                    )
                }
            }
            decl.diagnoseDirectStoreDotSend(declaration: decl, context: context)
        }
    }
}

extension DeclGroupSyntax {
    fileprivate var hasStoreVariable: Bool {
        memberBlock.members.contains(where: { member in
            if let variableDecl = member.decl.as(VariableDeclSyntax.self),
               let firstBinding = variableDecl.bindings.first,
               let identifierPattern = firstBinding.pattern.as(IdentifierPatternSyntax.self),
               identifierPattern.identifier.text == "store" {
                true
            } else {
                false
            }
        })
    }
}

extension DeclGroupSyntax {
    var identifierDescription: String? {
        switch self {
        case let syntax as ActorDeclSyntax:
            syntax.name.trimmedDescription
        case let syntax as ClassDeclSyntax:
            syntax.name.trimmedDescription
        case let syntax as ExtensionDeclSyntax:
            syntax.extendedType.trimmedDescription
        case let syntax as ProtocolDeclSyntax:
            syntax.name.trimmedDescription
        case let syntax as StructDeclSyntax:
            syntax.name.trimmedDescription
        case let syntax as EnumDeclSyntax:
            syntax.name.trimmedDescription
        default:
            nil
        }
    }
}

extension DeclModifierListSyntax {
    fileprivate func bindingSpecifier() -> TokenSyntax {
        guard
            let modifier = first(where: {
                $0.name.tokenKind == .keyword(.public) || $0.name.tokenKind == .keyword(.package)
            })
        else { return "let" }
        return "\(raw: modifier.name.text) let"
    }
}

extension FunctionCallExprSyntax {
    fileprivate var sendExpression: ExprSyntax? {
        guard
            let memberAccess = calledExpression.as(MemberAccessExprSyntax.self),
            memberAccess.declName.baseName.text == "send"
        else { return nil }

        if memberAccess.base?.as(DeclReferenceExprSyntax.self)?.baseName.text == "store" {
            return ExprSyntax(DeclReferenceExprSyntax(baseName: "send"))
        }

        if let innerMemberAccess = memberAccess.base?.as(MemberAccessExprSyntax.self),
           innerMemberAccess.base?.as(DeclReferenceExprSyntax.self)?.baseName.text == "self",
           innerMemberAccess.declName.baseName.text == "store" {
            return ExprSyntax(
                MemberAccessExprSyntax(base: DeclReferenceExprSyntax(baseName: "self"), name: "send")
            )
        }

        return nil
    }
}
