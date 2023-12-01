import SwiftUI
import Combine

class SuggestionViewModel: ObservableObject {
    let recordedString: RecordedString
    
    @Published var suggestion: String {
        didSet {
            UserLingua.shared.db.suggestions[self.recordedString.original, default: []] = [
                Suggestion(recordedString: self.recordedString, newValue: suggestion, locale: .current)
            ]
            UserLingua.shared.objectWillChange.send()
        }
    }
    
    private var cancellables: Set<AnyCancellable> = []
    
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
                                Text("File:")
                                Text(localization.tableName ?? "Localizable.strings")
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
            .frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.height/3)
        }
    }
}

struct HighlightsView: View {
    let userLingua = UserLingua.shared
    @State var selectedRecordedString: RecordedString?
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let selectedRecordedString {
                SuggestionView(recordedString: selectedRecordedString)
            } else {
                Color.black.opacity(0.1)
                    .mask {
                        highlights(color: .black)
                            .background(.white)
                            .compositingGroup()
                            .luminanceToAlpha()
                    }
                
                highlights(color: .white.opacity(0.001)) { recordedString in
                    UserLingua.shared.state = .previewingSuggestions
                    selectedRecordedString = recordedString
                }
            }
        }
        .ignoresSafeArea()
    }
    
    func highlights(color: Color, onTapGesture: @escaping (RecordedString) -> Void = { _ in }) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(userLingua.highlightedStrings.keys), id: \.self) { recordedString in
                ForEach(userLingua.highlightedStrings[recordedString, default: []]) { rect in
                    color
                        .cornerRadius(5)
                        .frame(width: rect.width + 20, height: rect.height + 20)
                        .position(x: rect.midX, y: UIScreen.main.bounds.height - rect.midY)
                        .onTapGesture {
                            onTapGesture(recordedString)
                        }
                }
            }
        }
        .ignoresSafeArea()
    }
}

extension CGRect: Identifiable {
    public var id: String {
        "\(self)"
    }
}
