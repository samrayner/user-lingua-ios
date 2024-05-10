// RecognizedLine.swift

import Foundation

package struct RecognizedLine: Equatable {
    package var string: String
    package var boundingBox: CGRect

    package init(string: String, boundingBox: CGRect) {
        self.string = string
        self.boundingBox = boundingBox
    }
}

extension RecognizedLine: Identifiable {
    package var id: String {
        "\(boundingBox.width)x\(boundingBox.height) at \(boundingBox.minX),\(boundingBox.minY)"
    }
}
