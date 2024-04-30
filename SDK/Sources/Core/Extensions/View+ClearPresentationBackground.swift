// View+ClearPresentationBackground.swift

import SwiftUI

extension View {
    package func clearPresentationBackground() -> some View {
        Group {
            if #available(iOS 16.4, *) {
                presentationBackground(.clear)
            } else {
                background(PresentationBackgroundRemovalView())
            }
        }
    }
}

private struct PresentationBackgroundRemovalView: UIViewRepresentable {
    private class BackgroundRemovalView: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()
            superview?.superview?.backgroundColor = .clear
        }
    }

    func makeUIView(context _: Context) -> UIView {
        BackgroundRemovalView()
    }

    func updateUIView(_: UIView, context _: Context) {}
}
