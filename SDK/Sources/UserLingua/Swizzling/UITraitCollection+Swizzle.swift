// UITraitCollection+Swizzle.swift

import Core
import UIKit

extension UITraitCollection {
    static func swizzle() {
        swizzle(
            original: #selector(getter: preferredContentSizeCategory),
            with: #selector(unswizzledPreferredContentSizeCategory)
        )
    }

    static func unswizzle() {
        swizzle(
            original: #selector(unswizzledPreferredContentSizeCategory),
            with: #selector(getter: preferredContentSizeCategory)
        )
    }

    // After swizzling, unswizzled... will refer to the original implementation
    // and the original method name will call the below implementation.
    @objc
    func unswizzledPreferredContentSizeCategory() -> UIContentSizeCategory {
        UserLinguaClient.shared.appContentSizeCategory
    }
}
