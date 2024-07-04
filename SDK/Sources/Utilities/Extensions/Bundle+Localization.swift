// Bundle+Localization.swift

import Foundation

extension Bundle {
    public func localized(localeIdentifier: String) -> Bundle? {
        path(
            forResource: localeIdentifier.replacingOccurrences(of: "_", with: "-"),
            ofType: "lproj"
        )
        .flatMap(Bundle.init(path:))
    }
}