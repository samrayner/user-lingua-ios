// RecognizedLine.swift

import Foundation

public struct RecognizedLine: Equatable {
    public var string: String
    public var boundingBox: CGRect

    public init(string: String, boundingBox: CGRect) {
        self.string = string
        self.boundingBox = boundingBox
    }
}

extension RecognizedLine: Identifiable {
    public var id: String {
        "\(boundingBox.width)x\(boundingBox.height) at \(boundingBox.minX),\(boundingBox.minY)"
    }
}
