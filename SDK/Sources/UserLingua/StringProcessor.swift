// StringProcessor.swift

import Spyable
import SwiftUI

@Spyable
protocol StringProcessorProtocol {
    func processLocalizedStringKey(_ key: LocalizedStringKey, state: UserLingua.State) -> String
    func processString(_ string: String, state: UserLingua.State) -> String
    func displayString(for formattedString: FormattedString, state: UserLingua.State) -> String
}

struct StringProcessor: StringProcessorProtocol {
    let stringExtractor: StringExtractorProtocol
    let stringsRepository: StringsRepositoryProtocol
    let suggestionsRepository: SuggestionsRepositoryProtocol

    func processLocalizedStringKey(_ key: LocalizedStringKey, state: UserLingua.State) -> String {
        let formattedString = stringExtractor.formattedString(
            localizedStringKey: key,
            locale: state.locale,
            tableName: nil,
            bundle: nil,
            comment: nil
        )

        if state == .recordingStrings {
            stringsRepository.record(formatted: formattedString)
        }

        return displayString(for: formattedString, state: state)
    }

    func processString(_ string: String, state: UserLingua.State) -> String {
        if state == .recordingStrings {
            stringsRepository.record(string: string)
        }

        return displayString(for: FormattedString(string), state: state)
    }

    func displayString(for formattedString: FormattedString, state: UserLingua.State) -> String {
        switch state {
        case .disabled, .highlightingStrings, .recordingStrings:
            return formattedString.value
        case .detectingStrings:
            guard let recordedString = stringsRepository.recordedString(formatted: formattedString) else {
                return formattedString.value
            }
            return recordedString.detectable
        case .previewingSuggestions:
            guard let suggestion = suggestionsRepository.suggestion(formatted: formattedString, locale: state.locale) else {
                return formattedString.value
            }
            return suggestion.newValue
        }
    }
}
