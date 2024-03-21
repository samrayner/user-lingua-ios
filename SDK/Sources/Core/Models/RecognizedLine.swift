// RecognizedLine.swift

import Foundation
import MemberwiseInit

@MemberwiseInit(.package)
package struct RecognizedLine: Equatable {
    package var string: String
    package var boundingBox: CGRect
}
