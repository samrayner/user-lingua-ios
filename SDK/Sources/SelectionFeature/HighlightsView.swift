// HighlightsView.swift

import Core
import SwiftUI

struct HighlightsView: View {
    let recognizedStrings: [RecognizedString]
    let onSelectString: (RecordedString) -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.white : Color.black)
                .opacity(0.1)
                .mask {
                    ZStack {
                        Color(.white)
                        highlights(color: .black)
                    }
                    .compositingGroup()
                    .luminanceToAlpha()
                }

            highlights(color: .white.opacity(0.001), onSelectString: onSelectString)
        }
        .ignoresSafeArea()
    }

    func highlights(color: Color, onSelectString: @escaping (RecordedString) -> Void = { _ in }) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(recognizedStrings, id: \.recordedString.detectable) { recognizedString in
                ForEach(recognizedString.lines, id: \.string) { line in
                    color
                        .cornerRadius(5)
                        .frame(width: line.boundingBox.width + 20, height: line.boundingBox.height + 20)
                        .position(x: line.boundingBox.midX, y: UIScreen.main.bounds.height - line.boundingBox.midY)
                        .onTapGesture {
                            onSelectString(recognizedString.recordedString)
                        }
                }
            }
        }
        .ignoresSafeArea()
    }
}
