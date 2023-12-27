// UserLinguaMacroTests.swift

import Macros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class UserLinguaMacroTests: XCTestCase {
    private let macros = ["UserLingua": UserLinguaMacro.self]

    func testExpansionAddsNestedMetaEnum() {
        assertMacroExpansion("""
                             @UserLingua struct MyView: View {
                             }
                             """,
                             expandedSource: """
                             struct MyView: View {

                                 @ObservedObject private (set) var userLinguaObservedObject = UserLingua.shared
                             }
                             """,
                             macros: macros,
                             indentationWidth: .spaces(4))
    }
}
