// Suggestion.swift

import Foundation
import UIKit

struct Suggestion {
    var recordedString: RecordedString
    var newValue: String
    var locale: Locale
    var createdAt: Date = .now
    var modifiedAt: Date = .now
    var isSubmitted = false
    var screenshot: UIImage?
}
