// SuggestionsRepository.swift

import Foundation
import Models

// sourcery: AutoMockable
public protocol SuggestionsRepositoryProtocol {
    func saveSuggestion(_ suggestion: Suggestion)
    func suggestion(for original: String, locale: Locale) -> Suggestion?
}

public final class SuggestionsRepository: SuggestionsRepositoryProtocol {
    private var suggestions: [String: [Locale: Suggestion]]

    public init(suggestions: [String: [Locale: Suggestion]] = [:]) {
        self.suggestions = suggestions
    }

    public func saveSuggestion(_ suggestion: Suggestion) {
        suggestions[suggestion.recordedString.value, default: [:]][suggestion.locale] = suggestion
    }

    public func suggestion(for original: String, locale: Locale) -> Suggestion? {
        suggestions[original, default: [:]][locale]
    }
}
