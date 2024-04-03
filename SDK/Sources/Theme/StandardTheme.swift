// StandardTheme.swift

import SFSafeSymbols

struct StandardTheme: ThemeProtocol {
    enum Palette {
        static let black = "#000000"
        static let white = "#FFFFFF"
        static let cyanLight = "#00ffff"
        static let cyanDark = "#00b3b3"
    }

    let colors = ThemeColors(
        foreground: .init(light: Palette.black, dark: Palette.white),
        background: .init(light: Palette.white, dark: Palette.black),
        accent: .init(light: Palette.cyanLight, dark: Palette.cyanDark)
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
