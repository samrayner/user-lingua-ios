// PrimaryButtonStyle.swift

import SwiftUI

package struct PrimaryButtonStyle: ButtonStyle {
    package func makeBody(configuration: Configuration) -> some View {
        PrimaryButton(configuration: configuration)
    }

    private struct PrimaryButton: View {
        let configuration: ButtonStyle.Configuration
        @Environment(\.isEnabled) private var isEnabled: Bool

        var body: some View {
            configuration.label
                .font(.theme(.Button.primary))
                .multilineTextAlignment(.center)
                .padding(.Space.m)
                .background(backgroundColor(isPressed: configuration.isPressed))
                .foregroundColor(foregroundColor)
                .cornerRadius(.infinity)
        }

        var foregroundColor: Color {
            .theme(isEnabled ? .Button.Primary.text : .Button.Primary.textDisabled)
        }

        func backgroundColor(isPressed: Bool) -> Color {
            guard isEnabled else {
                return .theme(.Button.Primary.backgroundDisabled)
            }

            return .theme(.Button.Primary.background)
                .opacity(isPressed ? .Opacity.heavy : .Opacity.opaque)
        }
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    package static var primary: PrimaryButtonStyle { .init() }
}

struct PrimaryButtonStylePreview: PreviewProvider {
    static var previews: some View {
        view
            .padding(10)
            .previewLayout(.sizeThatFits)
    }

    static var view: some View {
        VStack {
            Button("Enabled", action: {})
                .buttonStyle(.primary)

            Button("Disabled", action: {})
                .disabled(true)
                .buttonStyle(.primary)

            Button(action: {}) {
                Text("Custom size")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)
        }
    }
}
