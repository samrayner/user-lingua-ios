// StandardTheme.swift

struct StandardTheme: ThemeProtocol {
    enum Palette {
        static let black = "#000000"
        static let white = "#FFFFFF"
    }

    let colors = ThemeColors(
        foreground: .init(light: Palette.black, dark: Palette.white),
        background: .init(light: Palette.white, dark: Palette.black)
    )

    let fonts = ThemeFonts(
        bodyMedium: .system(
            weight: .regular,
            size: 16,
            relativeTo: .body
        )
    )

    let images = ThemeImages(
        close: .symbol(.xmarkCircleFill)
    )
}
