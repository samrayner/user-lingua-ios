// StringProcessor.swift

import Spyable
import SwiftUI

@Spyable
protocol StringProcessorProtocol {
    func processLocalizedStringKey(_ key: LocalizedStringKey, state: RootFeature.State) -> String
    func processString(_ string: String, state: RootFeature.State) -> String
    func displayString(for formattedString: FormattedString, state: RootFeature.State) -> String
}

struct StringProcessor: StringProcessorProtocol {
    let stringExtractor: StringExtractorProtocol
    let stringsRepository: StringsRepositoryProtocol
    let suggestionsRepository: SuggestionsRepositoryProtocol

    func processLocalizedStringKey(_ key: LocalizedStringKey, state: RootFeature.State) -> String {
        let formattedString = stringExtractor.formattedString(
            localizedStringKey: key,
            locale: state.locale,
            tableName: nil,
            bundle: nil,
            comment: nil
        )

        if state.mode == .recording {
            stringsRepository.record(formatted: formattedString)
        }

        return displayString(for: formattedString, state: state)
    }

    func processString(_ string: String, state: RootFeature.State) -> String {
        if state.mode == .recording {
            stringsRepository.record(string: string)
        }

        return displayString(for: FormattedString(string), state: state)
    }

    func displayString(for formattedString: FormattedString, state: RootFeature.State) -> String {
        switch state.mode {
        case let .selection(state) where state.isCapturingAppWindow:
            guard let recordedString = stringsRepository.recordedString(formatted: formattedString) else {
                return formattedString.value
            }
            return recordedString.detectable
        case .inspection:
            guard let suggestion = suggestionsRepository.suggestion(formatted: formattedString, locale: state.locale) else {
                return formattedString.value
            }
            return suggestion.newValue
        case .disabled, .recording, .selection:
            return formattedString.value
        }
    }
}
