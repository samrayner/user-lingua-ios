// LocalePickerView.swift

import Foundation
import SwiftUI

struct LocalePickerView: View {
    @Binding var selectedIdentifier: String

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(Bundle.main.preferredLocalizations.sorted(), id: \.self) { identifier in
                        Button(identifier) {
                            selectedIdentifier = identifier
                        }
                        .id(identifier)
                        .buttonStyle(LocalePickerButtonStyle(isSelected: identifier == selectedIdentifier))
                    }
                }
                .onAppear {
                    DispatchQueue.main.async {
                        proxy.scrollTo(selectedIdentifier, anchor: .center)
                    }
                }
            }
        }
    }
}

private struct LocalePickerButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .font(.theme(.localePickerButton))
            .padding(.vertical, .Space.s)
            .padding(.horizontal, .Space.m)
            .background(Color.theme(isSelected ? .localePickerButtonBackgroundSelected : .localePickerButtonBackground))
            .foregroundStyle(Color.theme(isSelected ? .localePickerButtonTextSelected : .localePickerButtonText))
            .cornerRadius(.infinity)
            .opacity(configuration.isPressed ? .Opacity.heavy : .Opacity.opaque)
    }
}
