// Lock.swift

import Foundation

extension NSLock {
    @inlinable
    @discardableResult
    func sync<R>(operation: () -> R) -> R {
        lock()
        defer { self.unlock() }
        return operation()
    }
}

extension NSRecursiveLock {
    @inlinable
    @discardableResult
    func sync<R>(operation: () -> R) -> R {
        lock()
        defer { self.unlock() }
        return operation()
    }
}
