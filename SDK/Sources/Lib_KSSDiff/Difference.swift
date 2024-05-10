// Difference.swift

import Foundation

/**
 Describe a single difference between two strings.
 */
public struct Difference {
    /// The substring of the difference in the original string.
    public var inOriginal: Substring?

    /// The substring of the difference in the new string.
    public var inNew: Substring?

    /// Returns `true` if the difference is a deletion. In this case `inOriginal` will be valid and `inNew` will be `nil`.
    public var isDelete: Bool { inOriginal != nil && inNew == nil }

    /// Returns `true` if the difference is an insertion. In this case `inNew` will be valid and `inOriginal` will be `nil`.
    public var isInsert: Bool { inOriginal == nil && inNew != nil }

    /// Returns `true` if the difference is a equality. In this case both `inOriginal` and `inNew` will be valid.
    public var isEqual: Bool { inOriginal != nil && inNew != nil }
}
