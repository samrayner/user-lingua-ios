// ThemeColor.swift

package struct ThemeColor {
    let designSystemColor: DesignSystemColor

    package func withAlphaComponent(_ alpha: Double) -> ThemeColor {
        Self(designSystemColor: designSystemColor.withAlphaComponent(alpha))
    }
}

extension ThemeColor {
    package init(_ designSystemColor: KeyPath<ThemeColors, DesignSystemColor>) {
        self.designSystemColor = Theme.current.theme.colors[keyPath: designSystemColor]
    }
}
