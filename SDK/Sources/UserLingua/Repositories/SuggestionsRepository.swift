// SuggestionsRepository.swift

import Dependencies
import Foundation
import Spyable

@Spyable
protocol SuggestionsRepositoryProtocol {
    func saveSuggestion(_ suggestion: Suggestion)
    func suggestion(recorded: RecordedString, locale: Locale) -> Suggestion?
    func suggestion(formatted: FormattedString, locale: Locale) -> Suggestion?
    func suggestion(localized: LocalizedString, locale: Locale) -> Suggestion?
    func suggestion(string: String, locale: Locale) -> Suggestion?
}

final class SuggestionsRepository: SuggestionsRepositoryProtocol {
    private var suggestions: [String: [Locale: Suggestion]]

    init(suggestions: [String: [Locale: Suggestion]] = [:]) {
        self.suggestions = suggestions
    }

    func saveSuggestion(_ suggestion: Suggestion) {
        suggestions[suggestion.recordedString.formatted.value, default: [:]][suggestion.locale] = suggestion
    }

    func suggestion(recorded recordedString: RecordedString, locale: Locale) -> Suggestion? {
        suggestion(formatted: recordedString.formatted, locale: locale)
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

enum SuggestionsRepositoryDependency: DependencyKey {
    static let liveValue: any SuggestionsRepositoryProtocol = { fatalError("Suggestions repository not supplied.") }()
    static let previewValue: any SuggestionsRepositoryProtocol = SuggestionsRepositoryProtocolSpy()
    static let testValue: any SuggestionsRepositoryProtocol = SuggestionsRepositoryProtocolSpy()
}
