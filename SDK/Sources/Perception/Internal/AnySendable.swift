// AnySendable.swift

struct AnySendable: @unchecked Sendable {
    let base: Any
    @inlinable
    init(_ base: some Sendable) {
        self.base = base
    }
}
