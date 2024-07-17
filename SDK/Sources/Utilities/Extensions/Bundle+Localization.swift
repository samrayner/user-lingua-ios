// Bundle+Localization.swift

import Foundation

extension Bundle {
    public var shouldIgnore: Bool {
        let shouldIgnore = bundleURL.pathExtension == "axbundle" ||
            bundleURL.lastPathComponent == "UIKitCore.framework"

        return shouldIgnore
    }

    public func localized(localeIdentifier: String) -> Bundle? {
        path(
            forResource: localeIdentifier.replacingOccurrences(of: "_", with: "-"),
            ofType: "lproj"
        )
        .flatMap(Bundle.init(path:))
    }
}
