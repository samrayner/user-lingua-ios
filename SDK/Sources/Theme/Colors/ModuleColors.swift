// ModuleColors.swift

import SwiftUI
import UIKit

package typealias ModuleColor = KeyPath<ThemeColors, ThemeColor>

/// Globally useful colour mappings for all modules.
/// Very few mappings should exist here as most will be module-specific.
/// Extend this type inside modules to declare `internal` colours.
package struct ModuleColors {
    fileprivate static let singleton = ModuleColors()

    package let text: ModuleColor = \.foreground
    package let background: ModuleColor = \.background
    package let tint: ModuleColor = \.primary
}

extension Color {
    package static func theme(_ keyPath: KeyPath<ModuleColors, ModuleColor>) -> Color {
        .init(uiColor: .theme(keyPath))
    }
}

extension UIColor {
    package static func theme(_ keyPath: KeyPath<ModuleColors, ModuleColor>) -> UIColor {
        let themeColor = ThemeColor(ModuleColors.singleton[keyPath: keyPath])
        return .init { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                themeColor.dark.uiColor
            case .light, .unspecified:
                themeColor.light.uiColor
            @unknown default:
                themeColor.light.uiColor
            }
        }
    }
}
