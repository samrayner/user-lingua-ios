// StandardTheme.swift

struct StandardTheme: ThemeProtocol {
    enum Palette {
        static let black = "#000000"
        static let white = "#FFFFFF"
    }

    let colors = ThemeColors(
        foreground: .init(Palette.black)
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
