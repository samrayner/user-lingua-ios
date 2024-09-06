// SuggestionsPersistence.swift

import Foundation
import GRDB
import Models

public protocol SuggestionsPersistence {
    func saveSuggestion(_ suggestion: Suggestion)
    func fetchSuggestion(for original: String, locale: Locale) -> Suggestion?
}

extension Database: SuggestionsPersistence {
    func saveSuggestion(_: Models.Suggestion) {
        fatalError()
    }

    func fetchSuggestion(for _: String, locale _: Locale) -> Models.Suggestion? {
        fatalError()
    }
}

extension Suggestion: Codable, FetchableRecord, MutablePersistableRecord {}
