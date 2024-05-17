// UserDefaults+UserLingua.swift

import Foundation

extension UserDefaults {
    package enum Keys {
        package static var textPreviewBaseIsExpanded: String { #function }
        package static var textPreviewOriginalIsExpanded: String { #function }
        package static var textPreviewDiffIsExpanded: String { #function }
        package static var textPreviewSuggestionIsExpanded: String { #function }
    }
}
