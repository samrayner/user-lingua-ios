// StandardTheme.swift

import SFSafeSymbols

struct StandardTheme: ThemeProtocol {
    enum Palette {
        static let slate = "#1D1B20"
        static let cloud = "#FEF7FF"
        static let cyanLight = "#00ffff"
        static let cyanDark = "#00b3b3"
    }

    let colors = ThemeColors(
        foreground: .init(light: Palette.cloud, dark: Palette.slate),
        background: .init(light: Palette.slate, dark: Palette.cloud),
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
        untoggleDarkMode: .symbol(.circleRighthalfFilled),
        enterFullScreen: .symbol(.arrowUpLeftAndArrowDownRight),
        exitFullScreen: .symbol(.arrowDownRightAndArrowUpLeft)
    )
}
