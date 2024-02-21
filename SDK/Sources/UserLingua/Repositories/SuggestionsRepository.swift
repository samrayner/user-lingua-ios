// SuggestionsRepository.swift

import Foundation
import Spyable

@Spyable
protocol SuggestionsRepositoryProtocol {
    func submitSuggestion(_ suggestion: Suggestion)
    func suggestion(localizedOriginal: LocalizedString, locale: Locale) -> Suggestion?
    func suggestion(original: String, locale: Locale) -> Suggestion?
}

final class SuggestionsRepository: SuggestionsRepositoryProtocol {
    private var suggestions: [String: [Locale: Suggestion]] = [:]

    init() {}

    func submitSuggestion(_ suggestion: Suggestion) {
        suggestions[suggestion.recordedString.original, default: [:]][suggestion.locale] = suggestion
    }

    func suggestion(original: String, locale: Locale) -> Suggestion? {
        suggestions[original, default: [:]][locale]
    }

    func suggestion(localizedOriginal: LocalizedString, locale: Locale) -> Suggestion? {
        suggestion(original: localizedOriginal.value, locale: locale)
    }
}
