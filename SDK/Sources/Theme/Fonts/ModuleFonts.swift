// ModuleFonts.swift

import SwiftUI
import UIKit

public typealias ModuleFont = KeyPath<ThemeFonts, ThemeFont>

/// Globally useful font mappings for all modules.
/// Very few mappings should exist here as most will be module-specific.
/// Extend this type inside modules to declare `internal` fonts.
public struct ModuleFonts {
    fileprivate static let singleton = Self()

    public let body: ModuleFont = \.bodyMedium
}

extension UIFont {
    public static func theme(_ keyPath: KeyPath<ModuleFonts, ModuleFont>) -> UIFont {
        ThemeFont(ModuleFonts.singleton[keyPath: keyPath]).uiFont
    }
}

extension Font {
    public static func theme(_ keyPath: KeyPath<ModuleFonts, ModuleFont>) -> Font {
        ThemeFont(ModuleFonts.singleton[keyPath: keyPath]).font
    }
}
