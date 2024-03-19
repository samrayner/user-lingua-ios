// FormatStyle+String.swift

import Foundation

extension FormatStyle {
    func string(for input: Any, locale: Locale) -> String? {
        guard let input = input as? FormatInput else { return nil }
        let formatter = self.locale(locale)
        return formatter.format(input) as? String
    }
}
