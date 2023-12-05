import UIKit

private extension NSObject {
    static func swizzle(original originalSelector: Selector, with newSelector: Selector) {
        guard let originalMethod = class_getInstanceMethod(self, originalSelector) else { return }
        guard let newMethod = class_getInstanceMethod(self, newSelector) else { return }
        
        if class_addMethod(self, originalSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)) {
            class_replaceMethod(self, newSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, newMethod)
        }
    }
}

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
