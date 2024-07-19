// LocalePickerView.swift

import Foundation
import Models
import Strings
import SwiftUI
import Utilities

struct LocalePickerView: View {
    @EnvironmentObject var configuration: ViewDependency<UserLinguaConfiguration>

    let localizationIdentifiers: Set<String>
    @Binding var selectedIdentifier: String

    var baseLocaleIdentifier: String {
        configuration.baseLocale.identifier(.bcp47)
    }

    var localizations: [String] {
        var localizations = localizationIdentifiers
        localizations.remove(baseLocaleIdentifier)
        return [baseLocaleIdentifier] + localizations.sorted()
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(localizations, id: \.self) { identifier in
                        Button(action: { selectedIdentifier = identifier }) {
                            if identifier == baseLocaleIdentifier {
                                Text("\(identifier) (\(Strings.Inspection.baseLocaleLabel))")
                            } else {
                                Text(identifier)
                            }
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
            .font(.theme(\.localePickerButton))
            .padding(.vertical, .Space.s)
            .padding(.horizontal, .Space.m)
            .background(Color.theme(isSelected ? \.localePickerButtonBackgroundSelected : \.localePickerButtonBackground))
            .foregroundStyle(Color.theme(isSelected ? \.localePickerButtonTextSelected : \.localePickerButtonText))
            .cornerRadius(.Radius.xs)
            .opacity(configuration.isPressed ? .Opacity.heavy : .Opacity.opaque)
    }
}
