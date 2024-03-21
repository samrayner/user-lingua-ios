// UTF16Char+UnicodeScalar.swift

import Foundation

extension UTF16Char {
    package var unicodeScalar: Unicode.Scalar? {
        Unicode.Scalar(UInt32(self))
    }
}
