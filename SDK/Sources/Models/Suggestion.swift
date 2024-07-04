// Suggestion.swift

import Foundation
import UIKit

public struct Suggestion: Equatable {
    public var recordedString: RecordedString
    public var newValue: String
    public var locale: Locale
    public var createdAt: Date
    public var modifiedAt: Date
    public var isSubmitted: Bool
    public var screenshot: UIImage?

    public init(
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
