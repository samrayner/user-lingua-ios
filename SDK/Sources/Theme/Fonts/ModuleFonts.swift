// ModuleFonts.swift

import SwiftUI
import UIKit

package typealias ModuleFont = KeyPath<ThemeFonts, ThemeFont>

/// Globally useful font mappings for all modules.
/// Very few mappings should exist here as most will be module-specific.
/// Extend this type inside modules to declare `internal` fonts.
package struct ModuleFonts {
    fileprivate static let singleton = Self()

    package let body: ModuleFont = \.bodyMedium
}

extension UIFont {
    package static func theme(_ keyPath: KeyPath<ModuleFonts, ModuleFont>) -> UIFont {
        ThemeFont(ModuleFonts.singleton[keyPath: keyPath]).uiFont
    }
}

extension Font {
    package static func theme(_ keyPath: KeyPath<ModuleFonts, ModuleFont>) -> Font {
        ThemeFont(ModuleFonts.singleton[keyPath: keyPath]).font
    }
}
