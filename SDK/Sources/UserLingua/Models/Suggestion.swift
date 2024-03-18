// Suggestion.swift

import Foundation
import UIKit

struct Suggestion: Equatable {
    var recordedString: RecordedString
    var newValue: String
    var locale: Locale
    var createdAt: Date = .now
    var modifiedAt: Date = .now
    var isSubmitted = false
    var screenshot: UIImage?
}
