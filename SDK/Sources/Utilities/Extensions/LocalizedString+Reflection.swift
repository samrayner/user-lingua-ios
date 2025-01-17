// LocalizedString+Reflection.swift

import SwiftUI

extension LocalizedStringResource {
    public var bundle: Bundle? {
        let bundleURL = Reflection.value("_bundleURL", on: self) as? URL
        let localeIdentifier = locale.identifier

        return (bundleURL.flatMap(Bundle.init(url:)) ?? .main)
            .localized(localeIdentifier: localeIdentifier)
    }
}

extension String.LocalizationValue {
    public var key: String? {
        Reflection.value("key", on: self) as? String
    }
}
