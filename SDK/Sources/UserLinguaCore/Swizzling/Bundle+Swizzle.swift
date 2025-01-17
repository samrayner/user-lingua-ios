// Bundle+Swizzle.swift

import Models
import UIKit

extension Bundle {
    static func swizzleBundle() {
        swizzle(
            original: #selector(localizedString(forKey:value:table:)),
            with: #selector(unswizzledLocalizedString(forKey:value:table:))
        )
    }

    static func unswizzleBundle() {
        swizzle(
            original: #selector(unswizzledLocalizedString(forKey:value:table:)),
            with: #selector(localizedString(forKey:value:table:))
        )
    }

    // After swizzling, unswizzled... will refer to the original implementation
    // and the original method name will call the below implementation.
    @objc
    func unswizzledLocalizedString(forKey key: String, value: String?, table: String?) -> String {
        let value = unswizzledLocalizedString(forKey: key, value: value, table: table)

        UserLinguaClient.shared.record(
            value: value,
            key: key,
            bundle: self,
            tableName: table,
            comment: nil
        )

        return value
    }
}
