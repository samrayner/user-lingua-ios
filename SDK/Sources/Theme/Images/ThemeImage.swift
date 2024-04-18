// ThemeImage.swift

import Foundation
import SFSafeSymbols
import SwiftUI
import UIKit

package struct ThemeImage {
    enum Source {
        case resource(ImageResource)
        case symbol(SFSymbol)
    }

    private let source: Source

    static func resource(_ resource: ImageResource) -> Self {
        self.init(source: .resource(resource))
    }

    static func symbol(_ symbol: SFSymbol) -> Self {
        self.init(source: .symbol(symbol))
    }

    fileprivate var image: Image {
        switch source {
        case let .resource(resource):
            Image(resource)
        case let .symbol(symbol):
            Image(systemSymbol: symbol)
        }
    }

    fileprivate var uiImage: UIImage {
        switch source {
        case let .resource(resource):
            UIImage(resource: resource)
        case let .symbol(symbol):
            UIImage(systemSymbol: symbol)
        }
    }
}

extension ThemeImage {
    package init(_ themeImage: KeyPath<ThemeImages, ThemeImage>) {
        self = Theme.current.theme.images[keyPath: themeImage]
    }
}

extension UIImage {
    package static func theme(_ themeImage: ThemeImage) -> UIImage {
        themeImage.uiImage
    }
}

extension Image {
    package static func theme(_ themeImage: ThemeImage) -> Image {
        themeImage.image
    }
}