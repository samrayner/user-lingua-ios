// PrimaryButtonStyle.swift

import SwiftUI

public struct PrimaryButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        PrimaryButton(configuration: configuration)
    }

    private struct PrimaryButton: View {
        let configuration: ButtonStyle.Configuration
        @Environment(\.isEnabled) private var isEnabled: Bool

        var body: some View {
            configuration.label
                .font(.theme(\.primaryButton))
                .multilineTextAlignment(.center)
                .padding(.Space.m)
                .background(backgroundColor(isPressed: configuration.isPressed))
                .foregroundColor(foregroundColor)
                .cornerRadius(.infinity)
        }

        var foregroundColor: Color {
            .theme(isEnabled ? \.primaryButtonText : \.primaryButtonTextDisabled)
        }

        func backgroundColor(isPressed: Bool) -> Color {
            guard isEnabled else {
                return .theme(\.primaryButtonBackgroundDisabled)
            }

            return .theme(\.primaryButtonBackground)
                .opacity(isPressed ? .Opacity.heavy : .Opacity.opaque)
        }
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    public static var primary: PrimaryButtonStyle { .init() }
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
