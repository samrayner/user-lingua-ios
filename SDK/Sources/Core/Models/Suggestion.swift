// Suggestion.swift

import Foundation
import UIKit

package struct Suggestion: Equatable {
    package var recordedString: RecordedString
    package var newValue: String
    package var locale: Locale
    package var createdAt: Date
    package var modifiedAt: Date
    package var isSubmitted: Bool
    package var screenshot: UIImage?

    package init(
        recordedString: RecordedString,
        newValue: String,
        locale: Locale,
        createdAt: Date = .now,
        modifiedAt: Date = .now,
        isSubmitted: Bool = false,
        screenshot: UIImage? = nil
    ) {
        self.recordedString = recordedString
        self.newValue = newValue
        self.locale = locale
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.isSubmitted = isSubmitted
        self.screenshot = screenshot
    }
}
