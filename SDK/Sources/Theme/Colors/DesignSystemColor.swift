// DesignSystemColor.swift

import Foundation
import SwiftUI
import UIKit

package struct DesignSystemColor {
    fileprivate let rgba: RGBA

    func withAlphaComponent(_ alpha: Double) -> DesignSystemColor {
        Self(rgba: RGBA(red: rgba.red, green: rgba.green, blue: rgba.blue, alpha: alpha))
    }
}

extension DesignSystemColor {
    init(_ hexadecimal: String) {
        self.rgba = .init(hexadecimal: hexadecimal)
    }
}

extension UIColor {
    package static func theme(_ themeColor: ThemeColor) -> UIColor {
        themeColor.designSystemColor.rgba.uiColor
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
        themeColor.designSystemColor.rgba.color
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
    init(hexadecimal: String) {
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
