// ModuleColors.swift

import SwiftUI
import UIKit

public typealias ModuleColor = KeyPath<ThemeColors, ThemeColor>

/// Globally useful colour mappings for all modules.
/// Very few mappings should exist here as most will be module-specific.
/// Extend this type inside modules to declare `internal` colours.
public struct ModuleColors {
    fileprivate static let singleton = ModuleColors()

    public let text: ModuleColor = \.foreground
    public let background: ModuleColor = \.background
    public let tint: ModuleColor = \.primary
}

extension Color {
    public static func theme(_ keyPath: KeyPath<ModuleColors, ModuleColor>) -> Color {
        .init(uiColor: .theme(keyPath))
    }
}

extension UIColor {
    public static func theme(_ keyPath: KeyPath<ModuleColors, ModuleColor>) -> UIColor {
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
