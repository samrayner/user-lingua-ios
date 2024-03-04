// Bundle+Localization.swift

import Foundation

extension Bundle {
    func localized(locale: Locale) -> Bundle? {
        locale.language.languageCode.flatMap { localized(languageCode: $0.identifier) }
    }

    func localized(languageCode: String) -> Bundle? {
        path(
            forResource: languageCode.replacingOccurrences(of: "_", with: "-"),
            ofType: "lproj"
        )
        .flatMap(Bundle.init(path:))
    }
}
