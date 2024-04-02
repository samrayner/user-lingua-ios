// SuggestionsRepository.swift

import Dependencies
import Foundation
import Spyable

@Spyable
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

package enum SuggestionsRepositoryDependency: DependencyKey {
    package static let liveValue: any SuggestionsRepositoryProtocol = SuggestionsRepository()
    package static let previewValue: any SuggestionsRepositoryProtocol = SuggestionsRepositoryProtocolSpy()
    package static let testValue: any SuggestionsRepositoryProtocol = SuggestionsRepositoryProtocolSpy()
}
