// SuggestionsRepository.swift

import Foundation
import Spyable

@Spyable
protocol SuggestionsRepositoryProtocol {
    func submitSuggestion(_ suggestion: Suggestion)
    func suggestion(formatted: FormattedString, locale: Locale) -> Suggestion?
    func suggestion(localized: LocalizedString, locale: Locale) -> Suggestion?
    func suggestion(string: String, locale: Locale) -> Suggestion?
}

final class SuggestionsRepository: SuggestionsRepositoryProtocol {
    private var suggestions: [String: [Locale: Suggestion]]

    init(suggestions: [String: [Locale: Suggestion]] = [:]) {
        self.suggestions = suggestions
    }

    func submitSuggestion(_ suggestion: Suggestion) {
        suggestions[suggestion.recordedString.formatted.value, default: [:]][suggestion.locale] = suggestion
    }

    func suggestion(formatted formattedString: FormattedString, locale: Locale) -> Suggestion? {
        if let localizedString = formattedString.format.localized {
            suggestion(localized: localizedString, locale: locale)
        } else {
            suggestion(string: formattedString.value, locale: locale)
        }
    }

    func suggestion(format: StringFormat, locale: Locale) -> Suggestion? {
        if let localizedString = format.localized {
            suggestion(localized: localizedString, locale: locale)
        } else {
            suggestion(string: format.value, locale: locale)
        }
    }

    func suggestion(localized localizedString: LocalizedString, locale: Locale) -> Suggestion? {
        suggestion(string: localizedString.value, locale: locale)
    }

    func suggestion(string: String, locale: Locale) -> Suggestion? {
        suggestions[string, default: [:]][locale]
    }
}
