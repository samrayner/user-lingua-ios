// UIView+ToggleDarkMode.swift

import UIKit

extension UIView {
    package func toggleDarkMode() {
        let uiStyle = if overrideUserInterfaceStyle == .unspecified {
            UIScreen.main.traitCollection.userInterfaceStyle
        } else {
            overrideUserInterfaceStyle
        }

        let newValue: UIUserInterfaceStyle = switch uiStyle {
        case .dark: .light
        case .light: .dark
        // should never be unspecified as we fell back to the
        // main screen trait collection which should always be set
        case .unspecified: .dark
        @unknown default: .dark
        }

        overrideUserInterfaceStyle = newValue
    }
}
