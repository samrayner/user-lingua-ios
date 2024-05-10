// StandardTheme.swift

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
        static let greenLight = "#5faf4e"
        static let greenDark = "#1E5128"
        static let redLight = "#dc5366"
        static let redDark = "#872341"
    }

    let colors = ThemeColors(
        foreground: .init(light: Palette.slate, dark: Palette.linen),
        background: .init(light: Palette.linen, dark: Palette.slate),
        well: .init(light: Palette.rainCloud, dark: Palette.black),
        surface: .init(light: Palette.white, dark: Palette.stone),
        surfaceDim: .init(light: Palette.offWhite, dark: Palette.graphite),
        primary: .init(light: Palette.cyanDark, dark: Palette.cyanLight),
        onPrimary: .init(light: Palette.linen, dark: Palette.slate),
        positive: .init(light: Palette.greenDark, dark: Palette.greenLight),
        negative: .init(light: Palette.redDark, dark: Palette.redLight)
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
        headingMedium: .system(
            weight: .bold,
            size: 14
        ),
        headingSmall: .system(
            weight: .bold,
            size: 12
        )
    )

    let images = ThemeImages(
        close: .symbol("xmark.circle.fill"),
        increaseTextSize: .symbol("textformat.size.larger"),
        decreaseTextSize: .symbol("textformat.size.smaller"),
        toggleDarkMode: .symbol("circle.lefthalf.filled"),
        enterFullScreen: .symbol("arrow.up.left.and.arrow.down.right"),
        exitFullScreen: .symbol("arrow.down.right.and.arrow.up.left"),
        doneSuggesting: .symbol("chevron.down"),
        textPreviewMode: .symbol("paragraphsign"),
        appPreviewMode: .symbol("eye"),
        textPreviewExpand: .symbol("chevron.down"),
        textPreviewCollapse: .symbol("chevron.up")
    )
}
