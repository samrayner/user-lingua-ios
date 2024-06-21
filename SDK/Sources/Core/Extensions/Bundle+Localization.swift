// Bundle+Localization.swift

import Foundation

extension Bundle {
    package func localized(localeIdentifier: String) -> Bundle? {
        path(
            forResource: localeIdentifier.replacingOccurrences(of: "_", with: "-"),
            ofType: "lproj"
        )
        .flatMap(Bundle.init(path:))
    }
}
