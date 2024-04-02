// ThemeImage.swift

import Foundation

package struct ThemeImage {
    let designSystemImage: DesignSystemImage

    package init(_ designSystemImage: KeyPath<ThemeImages, DesignSystemImage>) {
        self.designSystemImage = Theme.current.theme.images[keyPath: designSystemImage]
    }
}
