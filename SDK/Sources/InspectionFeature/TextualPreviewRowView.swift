// TextualPreviewRowView.swift

import SwiftUI

struct TextualPreviewRowView: View {
    @Binding var isExpanded: Bool

    let title: Text
    let content: Text

    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                content
                    .font(.theme(\.textualPreviewString))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, .Space.s)
            },
            label: {
                title
                    .font(.theme(\.textualPreviewHeading))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        )
        .padding(.Space.l)
    }
}
