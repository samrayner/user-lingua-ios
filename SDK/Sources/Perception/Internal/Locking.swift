// Locking.swift

import Foundation

struct _ManagedCriticalState<State> {
    private let lock = NSLock()
    private final class LockedBuffer: ManagedBuffer<State, UnsafeRawPointer> {}

    private let buffer: ManagedBuffer<State, UnsafeRawPointer>

    init(_ buffer: ManagedBuffer<State, UnsafeRawPointer>) {
        self.buffer = buffer
    }

    init(_ initial: State) {
        let roundedSize =
            (MemoryLayout<UnsafeRawPointer>.size - 1) / MemoryLayout<UnsafeRawPointer>.size
        self.init(
            LockedBuffer.create(minimumCapacity: Swift.max(roundedSize, 1)) { _ in
                initial
            }
        )
    }

    func withCriticalRegion<R>(
        _ critical: (inout State) throws -> R
    ) rethrows -> R {
        try buffer.withUnsafeMutablePointers { header, _ in
            lock.lock()
            defer {
                self.lock.unlock()
            }
            return try critical(&header.pointee)
        }
    }
}

extension _ManagedCriticalState: @unchecked Sendable where State: Sendable {}

extension _ManagedCriticalState: Identifiable {
    var id: ObjectIdentifier {
        ObjectIdentifier(buffer)
    }
}

extension NSLock {
    @inlinable @discardableResult
    @_spi(Internals)
    public func sync<R>(work: () -> R) -> R {
        lock()
        defer { self.unlock() }
        return work()
    }
}
