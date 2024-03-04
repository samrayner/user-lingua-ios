// SuggestionView.swift

import SwiftUI

class SuggestionViewModel: ObservableObject {
    let recordedString: RecordedString
    var languageIdentifier: String = Locale.current.identifier {
        didSet {
            let locale = Locale(identifier: languageIdentifier)
            UserLingua.shared.state = .previewingSuggestions(locale: locale)
            suggestion = UserLingua.shared.suggestionsRepository.suggestion(
                formatted: recordedString.formatted,
                locale: locale
            )?.newValue ?? recordedString.localizedValue(locale: locale)
        }
    }

    @Published var suggestion: String {
        didSet {
            UserLingua.shared.suggestionsRepository.submitSuggestion(
                Suggestion(recordedString: recordedString, newValue: suggestion, locale: .current)
            )
            UserLingua.shared.refreshViews()
        }
    }

    init(recordedString: RecordedString) {
        self.recordedString = recordedString
        self.suggestion = recordedString.formatted.value
    }
}

struct SuggestionView: View {
    @ObservedObject var viewModel: SuggestionViewModel

    init(recordedString: RecordedString) {
        self.viewModel = .init(recordedString: recordedString)
    }

    var body: some View {
        VStack {
            Spacer()

            Form {
                Picker("Language", selection: $viewModel.languageIdentifier) {
                    ForEach(Bundle.main.preferredLocalizations, id: \.self) { identifier in
                        Text(Locale.current.localizedString(forIdentifier: identifier) ?? "")
                    }
                }
                .pickerStyle(.segmented)
                .frame(height: 50)

                Section("Suggestion") {
                    TextField("Hi!", text: $viewModel.suggestion)
                }

                if let localization = viewModel.recordedString.localization {
                    Section("Localization") {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Key:")
                                Text(localization.key)
                            }

                            HStack {
                                Text("Table:")
                                Text(localization.tableName ?? "Localizable")
                            }

                            HStack {
                                Text("Comment:")
                                Text(localization.comment ?? "[None]")
                            }
                        }
                    }
                }
            }
            .shadow(radius: 10)
            .frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.height / 3)
        }
    }
}
