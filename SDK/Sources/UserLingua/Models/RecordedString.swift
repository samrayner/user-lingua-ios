// RecordedString.swift

import Foundation

struct RecordedString {
    let formatted: FormattedString
    let detectable: String
    let recordedAt: Date = .now

    init(_ formatted: FormattedString) {
        self.formatted = formatted
        self.detectable = formatted.value.tokenized()
    }

    var localization: Localization? {
        formatted.localization
    }

    var value: String {
        formatted.value
    }
}
