// SuggestionView.swift

import SwiftUI

class SuggestionViewModel: ObservableObject {
    let recordedString: RecordedString

    @Published var suggestion: String {
        didSet {
            UserLingua.shared.db.suggestions[recordedString.original, default: []] = [
                Suggestion(recordedString: recordedString, newValue: suggestion, locale: .current)
            ]
            UserLingua.shared.refreshViews()
        }
    }

    init(recordedString: RecordedString) {
        self.recordedString = recordedString
        self.suggestion = recordedString.original
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
