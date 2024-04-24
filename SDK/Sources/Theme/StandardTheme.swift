// StandardTheme.swift

import SFSafeSymbols

struct StandardTheme: ThemeProtocol {
    enum Palette {
        static let black = "#000000"
        static let slate = "#222222"
        static let graphite = "#2e2e2e"
        static let stone = "#444444"
        static let rainCloud = "#bbbbbb"
        static let linen = "#dddddd"
        static let offWhite = "#e5e5e5"
        static let white = "#FFFFFF"
        static let cyanLight = "#00ffff"
        static let cyanDark = "#00b3b3"
    }

    let colors = ThemeColors(
        foreground: .init(light: Palette.slate, dark: Palette.linen),
        background: .init(light: Palette.linen, dark: Palette.slate),
        well: .init(light: Palette.rainCloud, dark: Palette.black),
        surface: .init(light: Palette.white, dark: Palette.stone),
        surfaceDim: .init(light: Palette.offWhite, dark: Palette.graphite),
        primary: .init(light: Palette.cyanDark, dark: Palette.cyanLight),
        onPrimary: .init(light: Palette.linen, dark: Palette.slate)
    )

    let fonts = ThemeFonts(
        bodyMedium: .system(
            weight: .regular,
            size: 16
        ),
        bodySmall: .system(
            weight: .regular,
            size: 14
        ),
        button: .system(
            weight: .bold,
            size: 16
        ),
        labelSmall: .system(
            weight: .bold,
            size: 14
        ),
        headingSmall: .system(
            weight: .bold,
            size: 12
        )
    )

    let images = ThemeImages(
        close: .symbol(.xmarkCircleFill),
        increaseTextSize: .symbol(.textformatSizeLarger),
        decreaseTextSize: .symbol(.textformatSizeSmaller),
        toggleDarkMode: .symbol(.circleLefthalfFilled),
        untoggleDarkMode: .symbol(.circleRighthalfFilled),
        enterFullScreen: .symbol(.arrowUpLeftAndArrowDownRight),
        exitFullScreen: .symbol(.arrowDownRightAndArrowUpLeft),
        done: .symbol(.chevronDown),
        text: .symbol(.paragraphsign),
        vision: .symbol(.eye)
    )
}
