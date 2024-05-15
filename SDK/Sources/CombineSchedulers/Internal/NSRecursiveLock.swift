// NSRecursiveLock.swift

import Foundation

extension NSRecursiveLock {
    @inlinable @discardableResult
    func sync<R>(operation: () -> R) -> R {
        lock()
        defer { self.unlock() }
        return operation()
    }
}
