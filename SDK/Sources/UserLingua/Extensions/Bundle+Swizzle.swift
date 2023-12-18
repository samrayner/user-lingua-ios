import UIKit

extension Bundle {
    static func swizzle() {
        swizzle(
            original: #selector(localizedString(forKey:value:table:)),
            with: #selector(unswizzledLocalizedString(forKey:value:table:))
        )
    }
    
    // After swizzling, unswizzled... will refer to the original implementation
    // and the original method name will call the below implementation.
    @objc func unswizzledLocalizedString(forKey key: String, value: String?, table: String?) -> String {
        let value = unswizzledLocalizedString(forKey: key, value: value, table: table)
        UserLingua.shared.db.record(
            localizedString: LocalizedString(
                value: value,
                localization: Localization(key: key, bundle: self, tableName: table, comment: nil)
            )
        )
        return value
    }
}
