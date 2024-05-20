// SuggestionsRepository.swift

import Foundation

// sourcery: AutoMockable
package protocol SuggestionsRepositoryProtocol {
    func saveSuggestion(_ suggestion: Suggestion)
    func suggestion(for original: String, locale: Locale) -> Suggestion?
}

package final class SuggestionsRepository: SuggestionsRepositoryProtocol {
    private var suggestions: [String: [Locale: Suggestion]]

    package init(suggestions: [String: [Locale: Suggestion]] = [:]) {
        self.suggestions = suggestions
    }

    package func saveSuggestion(_ suggestion: Suggestion) {
        suggestions[suggestion.recordedString.value, default: [:]][suggestion.locale] = suggestion
    }

    package func suggestion(for original: String, locale: Locale) -> Suggestion? {
        suggestions[original, default: [:]][locale]
    }
}
