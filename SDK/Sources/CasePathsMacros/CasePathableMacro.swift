// CasePathableMacro.swift

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum CasePathableMacro {
    static let moduleName = "CasePaths"
    static let conformanceName = "CasePathable"
    static var qualifiedConformanceName: String { "\(moduleName).\(conformanceName)" }
    static var conformanceNames: [String] { [conformanceName, qualifiedConformanceName] }
    static let casePathTypeName = "AnyCasePath"
    static var qualifiedCasePathTypeName: String { "\(moduleName).\(casePathTypeName)" }
    static var qualifiedCaseTypeName: String { "\(moduleName).Case" }
}

extension CasePathableMacro: ExtensionMacro {
    public static func expansion(
        of _: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo _: [TypeSyntax],
        in _: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // if protocols.isEmpty {
        //   return []
        // }
        guard let enumDecl = declaration.as(EnumDeclSyntax.self)
        else {
            // TODO: Diagnostic?
            return []
        }
        if let inheritanceClause = enumDecl.inheritanceClause,
           inheritanceClause.inheritedTypes.contains(
               where: { Self.conformanceNames.contains($0.type.trimmedDescription) }
           ) {
            return []
        }
        let ext: DeclSyntax =
            """
            \(declaration.attributes.availability)extension \(type.trimmed): \(raw: Self.qualifiedConformanceName) {}
            """
        return [ext.cast(ExtensionDeclSyntax.self)]
    }
}

extension CasePathableMacro: MemberMacro {
    public static func expansion(
        of _: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in _: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self)
        else {
            throw DiagnosticsError(
                diagnostics: [
                    CasePathableMacroDiagnostic
                        .notAnEnum(declaration)
                        .diagnose(at: declaration.keyword)
                ]
            )
        }
        let enumName = enumDecl.name.trimmed

        let rewriter = SelfRewriter(selfEquivalent: enumName)
        let memberBlock = rewriter.rewrite(enumDecl.memberBlock).cast(MemberBlockSyntax.self)

        let enumCaseDecls = memberBlock
            .members
            .flatMap { $0.decl.as(EnumCaseDeclSyntax.self)?.elements ?? [] }

        var seenCaseNames: Set<String> = []
        for enumCaseDecl in enumCaseDecls {
            let name = enumCaseDecl.name.text
            if seenCaseNames.contains(name) {
                throw DiagnosticsError(
                    diagnostics: [
                        CasePathableMacroDiagnostic.overloadedCaseName(name).diagnose(
                            at: Syntax(enumCaseDecl.name)
                        )
                    ]
                )
            }
            seenCaseNames.insert(name)
        }

        let casePaths = generateDeclSyntax(from: memberBlock.members, enumName: enumName)

        return [
            """
            public struct AllCasePaths {
            \(raw: casePaths.map(\.description).joined(separator: "\n"))
            }
            public static var allCasePaths: AllCasePaths { AllCasePaths() }
            """
        ]
    }

    static func generateDeclSyntax(
        from elements: MemberBlockItemListSyntax,
        enumName: TokenSyntax
    ) -> [DeclSyntax] {
        elements.flatMap {
            if let elements = $0.decl.as(EnumCaseDeclSyntax.self)?.elements {
                return generateDeclSyntax(from: elements, enumName: enumName)
            }
            if let ifConfigDecl = $0.decl.as(IfConfigDeclSyntax.self) {
                let ifClauses = ifConfigDecl.clauses.flatMap { decl -> [DeclSyntax] in
                    guard let elements = decl.elements?.as(MemberBlockItemListSyntax.self) else {
                        return []
                    }
                    let title = "\(decl.poundKeyword.text) \(decl.condition?.description ?? "")"
                    return ["\(raw: title)"]
                        + generateDeclSyntax(from: elements, enumName: enumName)
                }
                return ifClauses + ["#endif"]
            }
            return []
        }
    }

    static func generateDeclSyntax(
        from enumCaseDecls: EnumCaseElementListSyntax,
        enumName: TokenSyntax
    ) -> [DeclSyntax] {
        enumCaseDecls.map {
            let caseName = $0.name.trimmed
            let associatedValueName = $0.trimmedTypeDescription
            let hasPayload = $0.parameterClause.map { !$0.parameters.isEmpty } ?? false
            let bindingNames: String
            let returnName: String
            if hasPayload, let associatedValue = $0.parameterClause {
                let parameterNames = (0 ..< associatedValue.parameters.count)
                    .map { "v\($0)" }
                    .joined(separator: ", ")
                bindingNames = "(\(parameterNames))"
                returnName = associatedValue.parameters.count == 1 ? parameterNames : bindingNames
            } else {
                bindingNames = ""
                returnName = "()"
            }

            return """
            public var \(caseName): \
            \(raw: qualifiedCasePathTypeName)<\(enumName), \(raw: associatedValueName)> {
            \(raw: qualifiedCasePathTypeName)<\(enumName), \(raw: associatedValueName)>(
            embed: \(raw: hasPayload ? "\(enumName).\(caseName)" : "{ \(enumName).\(caseName) }"),
            extract: {
            guard case\(raw: hasPayload ? " let" : "").\(caseName)\(raw: bindingNames) = $0 else { \
            return nil \
            }
            return \(raw: returnName)
            }
            )
            }
            """
        }
    }
}

enum CasePathableMacroDiagnostic {
    case notAnEnum(DeclGroupSyntax)
    case overloadedCaseName(String)
}

extension CasePathableMacroDiagnostic: DiagnosticMessage {
    var message: String {
        switch self {
        case let .notAnEnum(decl):
            """
            '@CasePathable' cannot be applied to\
            \(decl.keywordDescription.map { " \($0)" } ?? "") type\
            \(decl.nameDescription.map { " '\($0)'" } ?? "")
            """
        case let .overloadedCaseName(name):
            """
            '@CasePathable' cannot be applied to overloaded case name '\(name)'
            """
        }
    }

    var diagnosticID: MessageID {
        switch self {
        case .notAnEnum:
            MessageID(domain: "MetaEnumDiagnostic", id: "notAnEnum")
        case .overloadedCaseName:
            MessageID(domain: "MetaEnumDiagnostic", id: "overloadedCaseName")
        }
    }

    var severity: DiagnosticSeverity {
        switch self {
        case .notAnEnum:
            .error
        case .overloadedCaseName:
            .error
        }
    }

    func diagnose(at node: Syntax) -> Diagnostic {
        Diagnostic(node: node, message: self)
    }
}

extension AttributeListSyntax {
    var availability: AttributeListSyntax? {
        var elements = [AttributeListSyntax.Element]()
        for element in self {
            if let availability = element.availability {
                elements.append(availability)
            }
        }
        if elements.isEmpty {
            return nil
        }
        return AttributeListSyntax(elements)
    }
}

extension AttributeListSyntax.Element {
    var availability: AttributeListSyntax.Element? {
        switch self {
        case let .attribute(attribute):
            if let availability = attribute.availability {
                return .attribute(availability)
            }
        case let .ifConfigDecl(ifConfig):
            if let availability = ifConfig.availability {
                return .ifConfigDecl(availability)
            }
        }
        return nil
    }
}

extension AttributeSyntax {
    var availability: AttributeSyntax? {
        if attributeName.identifier == "available" {
            self
        } else {
            nil
        }
    }
}

extension IfConfigClauseSyntax {
    var availability: IfConfigClauseSyntax? {
        if let availability = elements?.availability {
            with(\.elements, availability)
        } else {
            nil
        }
    }

    var clonedAsIf: IfConfigClauseSyntax {
        detached.with(\.poundKeyword, .poundIfToken())
    }
}

extension IfConfigClauseSyntax.Elements {
    var availability: IfConfigClauseSyntax.Elements? {
        switch self {
        case let .attributes(attributes):
            if let availability = attributes.availability {
                .attributes(availability)
            } else {
                nil
            }
        default:
            nil
        }
    }
}

extension IfConfigDeclSyntax {
    var availability: IfConfigDeclSyntax? {
        var elements = [IfConfigClauseListSyntax.Element]()
        for clause in clauses {
            if let availability = clause.availability {
                if elements.isEmpty {
                    elements.append(availability.clonedAsIf)
                } else {
                    elements.append(availability)
                }
            }
        }
        if elements.isEmpty {
            return nil
        } else {
            return with(\.clauses, IfConfigClauseListSyntax(elements))
        }
    }
}

extension DeclGroupSyntax {
    var keyword: Syntax {
        switch self {
        case let syntax as ActorDeclSyntax:
            Syntax(syntax.actorKeyword)
        case let syntax as ClassDeclSyntax:
            Syntax(syntax.classKeyword)
        case let syntax as ExtensionDeclSyntax:
            Syntax(syntax.extensionKeyword)
        case let syntax as ProtocolDeclSyntax:
            Syntax(syntax.protocolKeyword)
        case let syntax as StructDeclSyntax:
            Syntax(syntax.structKeyword)
        case let syntax as EnumDeclSyntax:
            Syntax(syntax.enumKeyword)
        default:
            Syntax(self)
        }
    }

    var keywordDescription: String? {
        switch self {
        case let syntax as ActorDeclSyntax:
            syntax.actorKeyword.trimmedDescription
        case let syntax as ClassDeclSyntax:
            syntax.classKeyword.trimmedDescription
        case let syntax as ExtensionDeclSyntax:
            syntax.extensionKeyword.trimmedDescription
        case let syntax as ProtocolDeclSyntax:
            syntax.protocolKeyword.trimmedDescription
        case let syntax as StructDeclSyntax:
            syntax.structKeyword.trimmedDescription
        case let syntax as EnumDeclSyntax:
            syntax.enumKeyword.trimmedDescription
        default:
            nil
        }
    }

    var nameDescription: String? {
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

extension EnumCaseElementListSyntax.Element {
    var trimmedTypeDescription: String {
        if var associatedValue = parameterClause, !associatedValue.parameters.isEmpty {
            if associatedValue.parameters.count == 1,
               let type = associatedValue.parameters.first?.type.trimmed {
                return type.is(SomeOrAnyTypeSyntax.self)
                    ? "(\(type))"
                    : "\(type)"
            } else {
                for index in associatedValue.parameters.indices {
                    associatedValue.parameters[index].type.trailingTrivia = ""
                    associatedValue.parameters[index].defaultValue = nil
                    if associatedValue.parameters[index].firstName?.tokenKind == .wildcard {
                        associatedValue.parameters[index].colon = nil
                        associatedValue.parameters[index].firstName = nil
                        associatedValue.parameters[index].secondName = nil
                    }
                }
                return "(\(associatedValue.parameters.trimmed))"
            }
        } else {
            return "Void"
        }
    }
}

extension SyntaxStringInterpolation {
    mutating func appendInterpolation(_ node: (some SyntaxProtocol)?) {
        if let node {
            appendInterpolation(node)
        }
    }
}

extension TypeSyntax {
    var identifier: String? {
        for token in tokens(viewMode: .all) {
            switch token.tokenKind {
            case let .identifier(identifier):
                return identifier
            default:
                break
            }
        }
        return nil
    }
}

final class SelfRewriter: SyntaxRewriter {
    let selfEquivalent: TokenSyntax

    init(selfEquivalent: TokenSyntax) {
        self.selfEquivalent = selfEquivalent
    }

    override func visit(_ node: IdentifierTypeSyntax) -> TypeSyntax {
        guard node.name.text == "Self"
        else { return super.visit(node) }
        return super.visit(node.with(\.name, selfEquivalent))
    }
}