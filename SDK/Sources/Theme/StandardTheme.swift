// StandardTheme.swift

import SFSafeSymbols

struct StandardTheme: ThemeProtocol {
    enum Palette {
        static let black = "#000000"
        static let slate = "#222222"
        static let cloud = "#DDDDDD"
        static let white = "#FFFFFF"
        static let cyanLight = "#00ffff"
        static let cyanDark = "#00b3b3"
    }

    let colors = ThemeColors(
        foreground: .init(light: Palette.white, dark: Palette.slate),
        background: .init(light: Palette.slate, dark: Palette.white),
        well: .init(light: Palette.black, dark: Palette.cloud),
        accent: .init(light: Palette.cyanLight, dark: Palette.cyanDark)
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
        untoggleDarkMode: .symbol(.circleRighthalfFilled),
        enterFullScreen: .symbol(.arrowUpLeftAndArrowDownRight),
        exitFullScreen: .symbol(.arrowDownRightAndArrowUpLeft)
    )
}
