// HighlightsView.swift

import SwiftUI

struct HighlightsView: View {
    let userLingua = UserLingua.shared
    @State private var selectedRecordedString: RecordedString?
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let selectedRecordedString {
                SuggestionView(recordedString: selectedRecordedString)
            } else {
                (colorScheme == .dark ? Color.white : Color.black)
                    .opacity(0.1)
                    .mask {
                        highlights(color: .black)
                            .background(.white)
                            .compositingGroup()
                            .luminanceToAlpha()
                    }

                highlights(color: .white.opacity(0.001)) { recordedString in
                    UserLingua.shared.state = .previewingSuggestions(locale: .current)
                    selectedRecordedString = recordedString
                }
            }
        }
        .ignoresSafeArea()
    }

    func highlights(color: Color, onTapGesture: @escaping (RecordedString) -> Void = { _ in }) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(userLingua.highlightedStrings, id: \.0.detectable) { recordedString, textBlocks in
                ForEach(textBlocks, id: \.string) { textBlock in
                    color
                        .cornerRadius(5)
                        .frame(width: textBlock.boundingBox.width + 20, height: textBlock.boundingBox.height + 20)
                        .position(x: textBlock.boundingBox.midX, y: UIScreen.main.bounds.height - textBlock.boundingBox.midY)
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
