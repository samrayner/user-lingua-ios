// Suggestion.swift

import Foundation
import MemberwiseInit
import UIKit

@MemberwiseInit(.package)
package struct Suggestion: Equatable {
    package var recordedString: RecordedString
    package var newValue: String
    package var locale: Locale
    package var createdAt: Date = .now
    package var modifiedAt: Date = .now
    package var isSubmitted: Bool = false
    package var screenshot: UIImage? = nil
}
