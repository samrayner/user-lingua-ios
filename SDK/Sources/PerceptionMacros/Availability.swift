// Availability.swift

import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension AttributeSyntax {
    var availability: AttributeSyntax? {
        if attributeName.identifier == "available" {
            self
        } else {
            nil
        }
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
