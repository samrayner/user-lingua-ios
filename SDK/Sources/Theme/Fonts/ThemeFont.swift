// ThemeFont.swift

import SwiftUI
import UIKit

package struct ThemeFont {
    enum Source {
        case system(weight: UIFont.Weight)
        case preinstalled(name: String)
    }

    private let source: Source
    private let size: CGFloat
    private let textStyle: UIFont.TextStyle
    private let design: UIFontDescriptor.SystemDesign

    private var metrics: UIFontMetrics {
        .init(forTextStyle: textStyle)
    }

    static func system(
        weight: UIFont.Weight,
        size: CGFloat,
        relativeTo textStyle: UIFont.TextStyle,
        design: UIFontDescriptor.SystemDesign = .default
    ) -> Self {
        self.init(
            source: .system(weight: weight),
            size: size,
            textStyle: textStyle,
            design: design
        )
    }

    static func preinstalled(
        _ name: String,
        size: CGFloat,
        relativeTo textStyle: UIFont.TextStyle
    ) -> Self {
        self.init(
            source: .preinstalled(name: name),
            size: size,
            textStyle: textStyle,
            design: .default
        )
    }

    fileprivate var font: Font {
        switch source {
        case let .system(weight: weight):
            .system(size: metrics.scaledValue(for: size), weight: .init(weight), design: .init(design))
        case let .preinstalled(name):
            .custom(name, size: metrics.scaledValue(for: size))
        }
    }

    fileprivate var uiFont: UIFont {
        switch source {
        case let .system(weight: weight):
            .systemFont(ofSize: metrics.scaledValue(for: size), weight: weight, design: design)
        case let .preinstalled(name):
            // if the preinstalled font can't be instantiated, fall back to system font.
            if let font = UIFont(name: name, size: metrics.scaledValue(for: size)) {
                metrics.scaledFont(for: font)
            } else {
                .systemFont(ofSize: metrics.scaledValue(for: size))
            }
        }
    }
}

extension ThemeFont {
    package init(_ keyPath: KeyPath<ThemeFonts, ThemeFont>) {
        self = Theme.current.theme.fonts[keyPath: keyPath]
    }
}

extension UIFont {
    package static func theme(_ themeFont: ThemeFont) -> UIFont {
        themeFont.uiFont
    }
}

extension Font {
    package static func theme(_ themeFont: ThemeFont) -> Font {
        themeFont.font
    }
}

extension UIFont {
    fileprivate static func systemFont(ofSize fontSize: CGFloat, weight: UIFont.Weight, design: UIFontDescriptor.SystemDesign) -> UIFont {
        let baseFont = Self.systemFont(ofSize: fontSize, weight: weight)
        guard let descriptor = baseFont.fontDescriptor.withDesign(design) else { return baseFont }
        return UIFont(descriptor: descriptor, size: fontSize)
    }
}

extension Font.Design {
    fileprivate init(_ design: UIFontDescriptor.SystemDesign) {
        switch design {
        case .monospaced:
            self = .monospaced
        case .rounded:
            self = .rounded
        case .serif:
            self = .serif
        default:
            self = .default
        }
    }
}

extension Font.TextStyle {
    fileprivate init(_ textStyle: UIFont.TextStyle) {
        switch textStyle {
        case .largeTitle:
            self = .largeTitle
        case .title1:
            self = .title
        case .title2:
            self = .title2
        case .title3:
            self = .title3
        case .headline:
            self = .headline
        case .subheadline:
            self = .subheadline
        case .body:
            self = .body
        case .callout:
            self = .callout
        case .caption1:
            self = .caption
        case .caption2:
            self = .caption2
        case .footnote:
            self = .footnote
        default:
            self = .body
        }
    }
}

extension Font.Weight {
    fileprivate init(_ weight: UIFont.Weight) {
        switch weight {
        case .ultraLight:
            self = .ultraLight
        case .thin:
            self = .thin
        case .light:
            self = .light
        case .regular:
            self = .regular
        case .medium:
            self = .medium
        case .semibold:
            self = .semibold
        case .bold:
            self = .bold
        case .heavy:
            self = .heavy
        case .black:
            self = .black
        default:
            self = .regular
        }
    }
}
