// UserLinguaMacroTests.swift

// Commented out because Macros aren't supported for SPM package targets
// so importing Macros breaks Previews when the SDK package is the target
// https://forums.swift.org/t/xcode-15-beta-no-such-module-error-with-swiftpm-and-macro/65486

// import UserLinguaMacros
// import SwiftSyntaxMacros
// import SwiftSyntaxMacrosTestSupport
// import XCTest
//
// final class UserLinguaMacroTests: XCTestCase {
//    private let macros = ["CopyEditable": CopyEditableMacro.self]
//
//    func testExpansionAddsNestedMetaEnum() {
//        assertMacroExpansion("""
//                             @CopyEditable struct MyView: View {
//                             }
//                             """,
//                             expandedSource: """
//                             struct MyView: View {
//
//                                 @ObservedObject private (set) var _userLinguaViewModel = UserLinguaClient.shared.viewModel
//                             }
//                             """,
//                             macros: macros,
//                             indentationWidth: .spaces(4))
//    }
// }
