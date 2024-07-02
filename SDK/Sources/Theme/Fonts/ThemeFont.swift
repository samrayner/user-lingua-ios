// ThemeFont.swift

import SwiftUI
import UIKit

public struct ThemeFont {
    public static var scaleFactor: CGFloat = 1.0

    enum Source {
        case system(weight: UIFont.Weight)
        case preinstalled(name: String)
    }

    private let source: Source
    private let size: CGFloat
    private let textStyle: UIFont.TextStyle?
    private let design: UIFontDescriptor.SystemDesign

    private var metrics: UIFontMetrics? {
        textStyle.map(UIFontMetrics.init)
    }

    private var scaledSize: CGFloat {
        metrics?.scaledValue(for: size) ?? size * Self.scaleFactor
    }

    static func system(
        weight: UIFont.Weight,
        size: CGFloat,
        relativeTo textStyle: UIFont.TextStyle? = nil,
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
        relativeTo textStyle: UIFont.TextStyle? = nil
    ) -> Self {
        self.init(
            source: .preinstalled(name: name),
            size: size,
            textStyle: textStyle,
            design: .default
        )
    }

    var font: Font {
        switch source {
        case let .system(weight: weight):
            .system(size: scaledSize, weight: .init(weight), design: .init(design))
        case let .preinstalled(name):
            .custom(name, size: scaledSize)
        }
    }

    var uiFont: UIFont {
        switch source {
        case let .system(weight: weight):
            .systemFont(ofSize: scaledSize, weight: weight, design: design)
        case let .preinstalled(name):
            // if the preinstalled font can't be instantiated, fall back to system font.
            if let font = UIFont(name: name, size: scaledSize) {
                metrics?.scaledFont(for: font) ?? font.withSize(scaledSize)
            } else {
                .systemFont(ofSize: scaledSize)
            }
        }
    }
}

extension ThemeFont {
    public init(_ moduleFont: ModuleFont) {
        self = Theme.current.theme.fonts[keyPath: moduleFont]
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
