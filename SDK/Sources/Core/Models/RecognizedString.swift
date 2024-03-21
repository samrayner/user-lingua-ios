// RecognizedString.swift

import MemberwiseInit

@MemberwiseInit(.package)
package struct RecognizedString: Equatable {
    package var recordedString: RecordedString
    package var lines: [RecognizedLine]
}
