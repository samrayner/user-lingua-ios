// SuggestionsRepository.swift

import Dependencies
import Foundation
import Spyable

@Spyable
package protocol SuggestionsRepositoryProtocol {
    func saveSuggestion(_ suggestion: Suggestion)
    func suggestion(recorded: RecordedString, locale: Locale) -> Suggestion?
    func suggestion(formatted: FormattedString, locale: Locale) -> Suggestion?
    func suggestion(localized: LocalizedString, locale: Locale) -> Suggestion?
    func suggestion(string: String, locale: Locale) -> Suggestion?
}

package final class SuggestionsRepository: SuggestionsRepositoryProtocol {
    private var suggestions: [String: [Locale: Suggestion]]

    package init(suggestions: [String: [Locale: Suggestion]] = [:]) {
        self.suggestions = suggestions
    }

    package func saveSuggestion(_ suggestion: Suggestion) {
        suggestions[suggestion.recordedString.formatted.value, default: [:]][suggestion.locale] = suggestion
    }

    package func suggestion(recorded recordedString: RecordedString, locale: Locale) -> Suggestion? {
        suggestion(formatted: recordedString.formatted, locale: locale)
    }

    package func suggestion(formatted formattedString: FormattedString, locale: Locale) -> Suggestion? {
        if let localizedString = formattedString.format.localized {
            suggestion(localized: localizedString, locale: locale)
        } else {
            suggestion(string: formattedString.value, locale: locale)
        }
    }

    package func suggestion(localized localizedString: LocalizedString, locale: Locale) -> Suggestion? {
        suggestion(string: localizedString.value, locale: locale)
    }

    package func suggestion(string: String, locale: Locale) -> Suggestion? {
        suggestions[string, default: [:]][locale]
    }
}

package enum SuggestionsRepositoryDependency: DependencyKey {
    package static let liveValue: any SuggestionsRepositoryProtocol = SuggestionsRepository()
    package static let previewValue: any SuggestionsRepositoryProtocol = SuggestionsRepositoryProtocolSpy()
    package static let testValue: any SuggestionsRepositoryProtocol = SuggestionsRepositoryProtocolSpy()
}
