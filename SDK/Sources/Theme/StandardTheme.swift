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
        foreground: .init(light: Palette.white, dark: Palette.black),
        background: .init(light: Palette.black, dark: Palette.white),
        accent: .init(light: Palette.cyanDark, dark: Palette.cyanLight)
    )

    let fonts = ThemeFonts(
        bodyMedium: .system(
            weight: .regular,
            size: 16
        )
    )

    let images = ThemeImages(
        close: .symbol(.xmarkCircleFill),
        increaseTextSize: .symbol(.textformatSizeLarger),
        decreaseTextSize: .symbol(.textformatSizeSmaller),
        toggleDarkMode: .symbol(.circleLefthalfFilled),
        untoggleDarkMode: .symbol(.circleRighthalfFilled)
    )
}
