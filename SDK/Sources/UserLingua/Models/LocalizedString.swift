import SwiftUI

package struct LocalizedString: Hashable {
    var value: String
    var localization: Localization
}

package struct Localization: Hashable {
    var key: String
    var bundle: Bundle?
    var tableName: String?
    var comment: String?
}

extension LocalizedString {
    package init(
        _ key: String,
        tableName: String? = nil,
        bundle: Bundle? = nil,
        comment: StaticString? = nil
    ) {
        let bundle = bundle ?? .main
        let value = bundle.localizedString(forKey: key, value: key, table: tableName)
        
        self.init(
            value: value,
            localization: .init(
                key: key,
                bundle: bundle,
                tableName: tableName,
                comment: String(describing: comment)
            )
        )
    }
}
