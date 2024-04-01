// RecognizedLine.swift

import Foundation
import MemberwiseInit

@MemberwiseInit(.package)
package struct RecognizedLine: Equatable {
    package var string: String
    package var boundingBox: CGRect
}

extension RecognizedLine: Identifiable {
    package var id: String {
        "\(boundingBox.width)x\(boundingBox.height) at \(boundingBox.minX),\(boundingBox.minY)"
    }
}
