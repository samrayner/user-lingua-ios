// StringFormat.swift

import Foundation
import MemberwiseInit

@MemberwiseInit(.package)
package struct StringFormat: Equatable {
    static let placeholderRegex: NSRegularExpression = {
        let int = "(?:h|hh|l|ll|q|z|t|j)?([dioux])"
        // valid flags for float
        let float = "[aefg]"
        // like in "%3$" to make positional specifiers
        let position = "([1-9]\\d*\\$)?"
        // precision like in "%1.2f"
        let precision = "[-+# 0]?\\d?(?:\\.\\d)?"

        let pattern = "(?:^|(?<!%)(?:%%)*)%\(position)\(precision)(@|\(int)|\(float)|[csp])"

        do {
            return try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        } catch {
            fatalError("Invalid regex pattern")
        }
    }()

    package var value: String
    package var localization: Localization?

    package var localized: LocalizedString? {
        localization.map { LocalizedString(value: value, localization: $0) }
    }

    package var isLocalized: Bool {
        localization != nil
    }

    package func localizedValue(locale: Locale) -> String {
        localization?.value(locale: locale) ?? value
    }
}

extension StringFormat {
    package init(_ string: String) {
        self.value = string
        self.localization = nil
    }

    package init(_ localizedString: LocalizedString) {
        self.value = localizedString.value
        self.localization = localizedString.localization
    }
}
