import UIKit

extension Bundle {
    static func swizzle() {
        swizzle(
            original: #selector(localizedString(forKey:value:table:)),
            with: #selector(swizzledLocalizedString(forKey:value:table:))
        )
    }
    
    @objc func swizzledLocalizedString(forKey key: String, value: String?, table: String?) -> String {
        let value = swizzledLocalizedString(forKey: key, value: value, table: table)
        UserLingua.shared.db.record(
            localizedString: LocalizedString(
                value: value,
                localization: Localization(key: key, bundle: self, tableName: table, comment: nil)
            )
        )
        return value
    }
}
