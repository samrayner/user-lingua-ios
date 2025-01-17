// ThemeImage.swift

import Foundation
import SwiftUI
import UIKit

public struct ThemeImage {
    enum Source {
        case resource(String)
        case symbol(String)
    }

    private let source: Source

    static func resource(_ resource: String) -> Self {
        self.init(source: .resource(resource))
    }

    static func symbol(_ symbol: String) -> Self {
        self.init(source: .symbol(symbol))
    }

    fileprivate var image: Image {
        switch source {
        case let .resource(resource):
            Image(resource)
        case let .symbol(symbol):
            Image(systemName: symbol)
        }
    }

    fileprivate var uiImage: UIImage {
        switch source {
        case let .resource(resource):
            UIImage(named: resource)!
        case let .symbol(symbol):
            UIImage(systemName: symbol)!
        }
    }
}

extension UIImage {
    public static func theme(_ keyPath: KeyPath<ThemeImages, ThemeImage>) -> UIImage {
        Theme.current.theme.images[keyPath: keyPath].uiImage
    }
}

extension Image {
    public static func theme(_ keyPath: KeyPath<ThemeImages, ThemeImage>) -> Image {
        Theme.current.theme.images[keyPath: keyPath].image
    }
}
