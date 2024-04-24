// LocalePickerButtonStyle.swift

import SwiftUI

struct LocalePickerButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Self.Configuration) -> some View {
        HStack(spacing: .Space.m) {
            configuration.label
                .frame(maxWidth: .infinity, alignment: .leading)

            if isSelected {
                Image.theme(.localePickerSelection)
                    .templated(color: .localePickerSelectionIndicator)
            }
        }
        .padding(.Space.l)
        .background(Color.theme(.localePickerButtonBackground))
        .opacity(configuration.isPressed ? .Opacity.heavy : .Opacity.opaque)
    }
}
