// ThemeColor.swift

import Foundation
import SwiftUI
import UIKit

typealias Hexadecimal = String

package struct ThemeColor {
    fileprivate let light: RGBA
    fileprivate let dark: RGBA

    func withAlphaComponent(_ alpha: Double) -> Self {
        Self(
            light: RGBA(red: light.red, green: light.green, blue: light.blue, alpha: alpha),
            dark: RGBA(red: dark.red, green: dark.green, blue: dark.blue, alpha: alpha)
        )
    }
}

extension ThemeColor {
    init(
        light: Hexadecimal,
        dark: Hexadecimal
    ) {
        self.light = .init(hexadecimal: light)
        self.dark = .init(hexadecimal: dark)
    }

    package init(_ keyPath: KeyPath<ThemeColors, ThemeColor>) {
        self = Theme.current.theme.colors[keyPath: keyPath]
    }
}

extension UIColor {
    package static func theme(_ themeColor: ThemeColor) -> UIColor {
        .init { traitCollection in
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

    package func adjust(
        hue: CGFloat = 0,
        saturation: CGFloat = 0,
        brightness: CGFloat = 0
    ) -> UIColor {
        var currentHue: CGFloat = 0.0
        var currentSaturation: CGFloat = 0.0
        var currentBrigthness: CGFloat = 0.0
        var currentAlpha: CGFloat = 0.0

        guard getHue(
            &currentHue,
            saturation: &currentSaturation,
            brightness: &currentBrigthness,
            alpha: &currentAlpha
        )
        else {
            return self
        }

        return .init(
            hue: currentHue + hue,
            saturation: currentSaturation + saturation,
            brightness: currentBrigthness + brightness,
            alpha: currentAlpha
        )
    }
}

extension Color {
    package static func theme(_ themeColor: ThemeColor) -> Color {
        .init(uiColor: .theme(themeColor))
    }

    package func adjust(
        hue: CGFloat = 0,
        saturation: CGFloat = 0,
        brightness: CGFloat = 0
    ) -> Color {
        Color(UIColor(self).adjust(hue: hue, saturation: saturation, brightness: brightness))
    }
}

private struct RGBA {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat

    var color: Color {
        .init(
            red: red,
            green: green,
            blue: blue
        ).opacity(alpha)
    }

    var uiColor: UIColor {
        .init(
            red: red,
            green: green,
            blue: blue,
            alpha: alpha
        )
    }
}

extension RGBA {
    init(hexadecimal: Hexadecimal) {
        var hexFormatted = hexadecimal.trimmingCharacters(in: .whitespacesAndNewlines)

        // swiftlint:disable identifier_name
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 1
        // swiftlint:enable identifier_name

        if hexFormatted.hasPrefix("#") {
            hexFormatted.remove(at: hexFormatted.startIndex)
        }

        var color: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&color)

        switch hexFormatted.count {
        case 6:
            r = CGFloat((color & 0xFF0000) >> 16) / 255
            g = CGFloat((color & 0x00FF00) >> 8) / 255
            b = CGFloat(color & 0x0000FF) / 255

        case 8:
            r = CGFloat((color & 0xFF00_0000) >> 24) / 255
            g = CGFloat((color & 0x00FF_0000) >> 16) / 255
            b = CGFloat((color & 0x0000_FF00) >> 8) / 255
            a = CGFloat(color & 0x0000_00FF) / 255

        default:
            assertionFailure("Only hex values with 6 and 8 chars are supported", file: #file, line: #line)
        }

        self.red = r
        self.green = g
        self.blue = b
        self.alpha = a
    }
}
