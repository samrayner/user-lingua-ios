// IdentifiedArray+Hashable.swift

extension IdentifiedArray: Hashable where Element: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(count)
        for element in self {
            hasher.combine(element)
        }
    }
}
