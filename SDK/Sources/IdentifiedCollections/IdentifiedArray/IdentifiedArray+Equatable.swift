// IdentifiedArray+Equatable.swift

extension IdentifiedArray: Equatable where Element: Equatable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.elements == rhs.elements
    }
}
