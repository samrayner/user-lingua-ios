// StringProcessor.swift

import Spyable
import SwiftUI

@Spyable
protocol StringProcessorProtocol {
    func processLocalizedStringKey(_ key: LocalizedStringKey, state: RootFeature.State) -> String
    func processString(_ string: String, mode: RootFeature.Mode.State) -> String
    func displayString(for formattedString: FormattedString, mode: RootFeature.Mode.State) -> String
}

struct StringProcessor: StringProcessorProtocol {
    let stringExtractor: StringExtractorProtocol
    let stringsRepository: StringsRepositoryProtocol
    let suggestionsRepository: SuggestionsRepositoryProtocol

    func processLocalizedStringKey(_ key: LocalizedStringKey, state: RootFeature.State) -> String {
        let formattedString = stringExtractor.formattedString(
            localizedStringKey: key,
            tableName: nil,
            bundle: nil,
            comment: nil
        )

        if state.mode == .recording {
            stringsRepository.record(formatted: formattedString)
        }

        return displayString(for: formattedString, mode: state.mode)
    }

    func processString(_ string: String, mode: RootFeature.Mode.State) -> String {
        if mode == .recording {
            stringsRepository.record(string: string)
        }

        return displayString(for: FormattedString(string), mode: mode)
    }

    func displayString(for formattedString: FormattedString, mode: RootFeature.Mode.State) -> String {
        switch mode {
        case let .selection(modeState) where modeState.stage == .takingScreenshot:
            guard let recordedString = stringsRepository.recordedString(formatted: formattedString) else {
                return formattedString.value
            }
            return recordedString.detectable
        case let .inspection(modeState) where modeState.recordedString.value == formattedString.value:
            guard let suggestion = suggestionsRepository.suggestion(formatted: formattedString, locale: modeState.locale) else {
                return formattedString.localizedValue(locale: modeState.locale)
            }
            return suggestion.newValue
        default:
            return formattedString.value
        }
    }
}
