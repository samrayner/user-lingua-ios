// LocalizedString+Reflection.swift

import SwiftUI

extension LocalizedStringResource {
    var bundle: Bundle? {
        let bundleURL = Reflection.value("_bundleURL", on: self) as? URL
        let localeIdentifier = locale.identifier

        return (bundleURL.flatMap(Bundle.init(url:)) ?? .main).path(
            forResource: localeIdentifier.replacingOccurrences(of: "_", with: "-"),
            ofType: "lproj"
        )
        .flatMap(Bundle.init(path:))
    }
}

extension String.LocalizationValue {
    var key: String? {
        Reflection.value("key", on: self) as? String
    }
}
