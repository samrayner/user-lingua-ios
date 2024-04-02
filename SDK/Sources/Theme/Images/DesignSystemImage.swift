// DesignSystemImage.swift

import SFSafeSymbols
import SwiftUI
import UIKit

package struct DesignSystemImage {
    enum Source {
        case asset(ImageResource)
        case symbol(SFSymbol)
    }

    private let source: Source

    static func asset(_ resource: ImageResource) -> Self {
        self.init(source: .asset(resource))
    }

    static func symbol(_ symbol: SFSymbol) -> Self {
        self.init(source: .symbol(symbol))
    }

    fileprivate var image: Image {
        switch source {
        case let .asset(resource):
            Image(resource)
        case let .symbol(symbol):
            Image(systemSymbol: symbol)
        }
    }

    fileprivate var uiImage: UIImage {
        switch source {
        case let .asset(resource):
            UIImage(resource: resource)
        case let .symbol(symbol):
            UIImage(systemSymbol: symbol)
        }
    }
}

extension UIImage {
    package static func theme(_ themeImage: ThemeImage) -> UIImage {
        themeImage.designSystemImage.uiImage
    }
}

extension Font {
    package static func theme(_ themeImage: ThemeImage) -> Image {
        themeImage.designSystemImage.image
    }
}
