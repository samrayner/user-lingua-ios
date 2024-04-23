// StandardTheme.swift

import SFSafeSymbols

struct StandardTheme: ThemeProtocol {
    enum Palette {
        static let black = "#000000"
        static let slate = "#222222"
        static let stone = "#444444"
        static let rainCloud = "#bbbbbb"
        static let linen = "#dddddd"
        static let white = "#FFFFFF"
        static let cyanLight = "#00ffff"
        static let cyanDark = "#00b3b3"
    }

    let colors = ThemeColors(
        foreground: .init(light: Palette.linen, dark: Palette.slate),
        background: .init(light: Palette.slate, dark: Palette.linen),
        well: .init(light: Palette.black, dark: Palette.rainCloud),
        surface: .init(light: Palette.stone, dark: Palette.white),
        primary: .init(light: Palette.cyanLight, dark: Palette.cyanDark),
        onPrimary: .init(light: Palette.slate, dark: Palette.linen)
    )

    let fonts = ThemeFonts(
        bodyMedium: .system(
            weight: .regular,
            size: 16
        ),
        labelSmall: .system(
            weight: .bold,
            size: 14
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
