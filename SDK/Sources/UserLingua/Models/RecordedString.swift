// RecordedString.swift

import Foundation

struct RecordedString: Hashable {
    let original: String
    let detectable: String
    let localization: Localization?
    let recordedAt: Date = .now

    init(_ original: String, localization: Localization?) {
        self.original = original
        self.detectable = original.tokenized()
        self.localization = localization
    }

    var localizedString: LocalizedString? {
        localization.map { .init(value: original, localization: $0) }
    }
}

extension RecordedString: Identifiable {
    var id: String {
        original
    }
}
