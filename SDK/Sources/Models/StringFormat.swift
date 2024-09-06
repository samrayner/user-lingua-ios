// StringFormat.swift

import Foundation

public struct StringFormat: Equatable, Codable {
    public static let placeholderRegex: NSRegularExpression = {
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

    public var value: String
    public var localization: Localization?

    public init(value: String, localization: Localization?) {
        self.value = value
        self.localization = localization
    }

    public var localized: LocalizedString? {
        localization.map { LocalizedString(value: value, localization: $0) }
    }

    public var isLocalized: Bool {
        localization != nil
    }

    public func localizedValue(locale: Locale) -> String {
        localization?.value(locale: locale) ?? value
    }
}

extension StringFormat {
    public init(_ string: String) {
        self.value = string
        self.localization = nil
    }

    public init(_ localizedString: LocalizedString) {
        self.value = localizedString.value
        self.localization = localizedString.localization
    }
}
