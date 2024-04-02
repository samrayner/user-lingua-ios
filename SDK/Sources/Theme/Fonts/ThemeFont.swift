// ThemeFont.swift

package struct ThemeFont {
    let designSystemFont: DesignSystemFont

    package init(_ designSystemFont: KeyPath<ThemeFonts, DesignSystemFont>) {
        self.designSystemFont = Theme.current.theme.fonts[keyPath: designSystemFont]
    }
}
