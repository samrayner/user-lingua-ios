// HighlightsView.swift

import SwiftUI

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
