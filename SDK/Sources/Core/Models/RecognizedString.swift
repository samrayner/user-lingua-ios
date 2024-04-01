// RecognizedString.swift

import Foundation
import MemberwiseInit

@MemberwiseInit(.package)
package struct RecognizedString: Equatable {
    package let id = UUID()
    package var recordedString: RecordedString
    package var lines: [RecognizedLine]
}

extension RecognizedString: Identifiable {}
