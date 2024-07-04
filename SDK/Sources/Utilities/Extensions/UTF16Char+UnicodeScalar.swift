// UTF16Char+UnicodeScalar.swift

import Foundation

extension UTF16Char {
    public var unicodeScalar: Unicode.Scalar? {
        Unicode.Scalar(UInt32(self))
    }
}
