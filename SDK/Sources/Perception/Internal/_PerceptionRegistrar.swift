// _PerceptionRegistrar.swift

struct _PerceptionRegistrar: Sendable {
    class ValuePerceptionStorage {
        func emit(_: some Any) -> Bool { false }
        func cancel() {}
    }

    private struct ValuesPerceptor {
        private let storage: ValuePerceptionStorage

        init(storage: ValuePerceptionStorage) {
            self.storage = storage
        }

        func emit(_ element: some Any) -> Bool {
            storage.emit(element)
        }

        func cancel() {
            storage.cancel()
        }
    }

    private struct State: @unchecked Sendable {
        private enum PerceptionKind {
            case willSetTracking(@Sendable () -> Void)
            case didSetTracking(@Sendable () -> Void)
            case computed(@Sendable (Any) -> Void)
            case values(ValuesPerceptor)
        }

        private struct Perception {
            private var kind: PerceptionKind
            var properties: Set<AnyKeyPath>

            init(kind: PerceptionKind, properties: Set<AnyKeyPath>) {
                self.kind = kind
                self.properties = properties
            }

            var willSetTracker: (@Sendable () -> Void)? {
                switch kind {
                case let .willSetTracking(tracker):
                    tracker
                default:
                    nil
                }
            }

            var didSetTracker: (@Sendable () -> Void)? {
                switch kind {
                case let .didSetTracking(tracker):
                    tracker
                default:
                    nil
                }
            }

            var perceptor: (@Sendable (Any) -> Void)? {
                switch kind {
                case let .computed(perceptor):
                    perceptor
                default:
                    nil
                }
            }

            var isValuePerceptor: Bool {
                switch kind {
                case .values:
                    true
                default:
                    false
                }
            }

            func emit(_ value: some Any) -> Bool {
                switch kind {
                case let .values(perceptor):
                    perceptor.emit(value)
                default:
                    false
                }
            }

            func cancel() {
                switch kind {
                case let .values(perceptor):
                    perceptor.cancel()
                default:
                    break
                }
            }
        }

        private var id = 0
        private var perceptions = [Int: Perception]()
        private var lookups = [AnyKeyPath: Set<Int>]()

        mutating func generateId() -> Int {
            defer { id &+= 1 }
            return id
        }

        mutating func registerTracking(
            for properties: Set<AnyKeyPath>, willSet perceptor: @Sendable @escaping () -> Void
        ) -> Int {
            let id = generateId()
            perceptions[id] = Perception(kind: .willSetTracking(perceptor), properties: properties)
            for keyPath in properties {
                lookups[keyPath, default: []].insert(id)
            }
            return id
        }

        mutating func registerTracking(
            for properties: Set<AnyKeyPath>, didSet perceptor: @Sendable @escaping () -> Void
        ) -> Int {
            let id = generateId()
            perceptions[id] = Perception(kind: .didSetTracking(perceptor), properties: properties)
            for keyPath in properties {
                lookups[keyPath, default: []].insert(id)
            }
            return id
        }

        mutating func registerComputedValues(
            for properties: Set<AnyKeyPath>, perceptor: @Sendable @escaping (Any) -> Void
        ) -> Int {
            let id = generateId()
            perceptions[id] = Perception(kind: .computed(perceptor), properties: properties)
            for keyPath in properties {
                lookups[keyPath, default: []].insert(id)
            }
            return id
        }

        mutating func registerValues(
            for properties: Set<AnyKeyPath>, storage: ValuePerceptionStorage
        ) -> Int {
            let id = generateId()
            perceptions[id] = Perception(
                kind: .values(ValuesPerceptor(storage: storage)), properties: properties
            )
            for keyPath in properties {
                lookups[keyPath, default: []].insert(id)
            }
            return id
        }

        func valuePerceptors(for keyPath: AnyKeyPath) -> Set<Int> {
            guard let ids = lookups[keyPath] else {
                return []
            }
            return ids.filter { perceptions[$0]?.isValuePerceptor == true }
        }

        mutating func cancel(_ id: Int) {
            if let perception = perceptions.removeValue(forKey: id) {
                for keyPath in perception.properties {
                    if var ids = lookups[keyPath] {
                        ids.remove(id)
                        if ids.count == 0 {
                            lookups.removeValue(forKey: keyPath)
                        } else {
                            lookups[keyPath] = ids
                        }
                    }
                }
                perception.cancel()
            }
        }

        mutating func cancelAll() {
            for perception in perceptions.values {
                perception.cancel()
            }
            perceptions.removeAll()
            lookups.removeAll()
        }

        mutating func willSet(keyPath: AnyKeyPath) -> [@Sendable () -> Void] {
            var trackers = [@Sendable () -> Void]()
            if let ids = lookups[keyPath] {
                for id in ids {
                    if let tracker = perceptions[id]?.willSetTracker {
                        trackers.append(tracker)
                    }
                }
            }
            return trackers
        }

        mutating func didSet(keyPath: KeyPath<some Perceptible, some Any>)
            -> ([@Sendable (Any) -> Void], [@Sendable () -> Void]) {
            var perceptors = [@Sendable (Any) -> Void]()
            var trackers = [@Sendable () -> Void]()
            if let ids = lookups[keyPath] {
                for id in ids {
                    if let perceptor = perceptions[id]?.perceptor {
                        perceptors.append(perceptor)
                        cancel(id)
                    }
                    if let tracker = perceptions[id]?.didSetTracker {
                        trackers.append(tracker)
                    }
                }
            }
            return (perceptors, trackers)
        }

        mutating func emit(_ value: some Any, ids: Set<Int>) {
            for id in ids {
                if perceptions[id]?.emit(value) == true {
                    cancel(id)
                }
            }
        }
    }

    struct Context: Sendable {
        private let state = _ManagedCriticalState(State())

        var id: ObjectIdentifier { state.id }

        func registerTracking(
            for properties: Set<AnyKeyPath>, willSet perceptor: @Sendable @escaping () -> Void
        ) -> Int {
            state.withCriticalRegion { $0.registerTracking(for: properties, willSet: perceptor) }
        }

        func registerTracking(
            for properties: Set<AnyKeyPath>, didSet perceptor: @Sendable @escaping () -> Void
        ) -> Int {
            state.withCriticalRegion { $0.registerTracking(for: properties, didSet: perceptor) }
        }

        func registerComputedValues(
            for properties: Set<AnyKeyPath>, perceptor: @Sendable @escaping (Any) -> Void
        ) -> Int {
            state.withCriticalRegion { $0.registerComputedValues(for: properties, perceptor: perceptor) }
        }

        func registerValues(for properties: Set<AnyKeyPath>, storage: ValuePerceptionStorage)
            -> Int {
            state.withCriticalRegion { $0.registerValues(for: properties, storage: storage) }
        }

        func cancel(_ id: Int) {
            state.withCriticalRegion { $0.cancel(id) }
        }

        func cancelAll() {
            state.withCriticalRegion { $0.cancelAll() }
        }

        func willSet<Subject: Perceptible>(
            _: Subject,
            keyPath: KeyPath<Subject, some Any>
        ) {
            let tracking = state.withCriticalRegion { $0.willSet(keyPath: keyPath) }
            for action in tracking {
                action()
            }
        }

        func didSet<Subject: Perceptible>(
            _ subject: Subject,
            keyPath: KeyPath<Subject, some Any>
        ) {
            let (ids, (actions, tracking)) = state.withCriticalRegion {
                ($0.valuePerceptors(for: keyPath), $0.didSet(keyPath: keyPath))
            }
            if !ids.isEmpty {
                let value = subject[keyPath: keyPath]
                state.withCriticalRegion { $0.emit(value, ids: ids) }
            }
            for action in tracking {
                action()
            }
            for action in actions {
                action(subject)
            }
        }
    }

    private final class Extent: @unchecked Sendable {
        let context = Context()

        init() {}

        deinit {
            context.cancelAll()
        }
    }

    var context: Context {
        extent.context
    }

    private var extent = Extent()

    init() {}

    /// Registers access to a specific property for observation.
    ///
    /// - Parameters:
    ///   - subject: An instance of an observable type.
    ///   - keyPath: The key path of an observed property.
    func access<Subject: Perceptible>(
        _: Subject,
        keyPath: KeyPath<Subject, some Any>
    ) {
        if let trackingPtr = _ThreadLocal.value?
            .assumingMemoryBound(to: PerceptionTracking._AccessList?.self) {
            if trackingPtr.pointee == nil {
                trackingPtr.pointee = PerceptionTracking._AccessList()
            }
            trackingPtr.pointee?.addAccess(keyPath: keyPath, context: context)
        }
    }

    /// A property observation called before setting the value of the subject.
    ///
    /// - Parameters:
    ///     - subject: An instance of an observable type.
    ///     - keyPath: The key path of an observed property.
    func willSet<Subject: Perceptible>(
        _ subject: Subject,
        keyPath: KeyPath<Subject, some Any>
    ) {
        context.willSet(subject, keyPath: keyPath)
    }

    /// A property observation called after setting the value of the subject.
    ///
    /// - Parameters:
    ///   - subject: An instance of an observable type.
    ///   - keyPath: The key path of an observed property.
    func didSet<Subject: Perceptible>(
        _ subject: Subject,
        keyPath: KeyPath<Subject, some Any>
    ) {
        context.didSet(subject, keyPath: keyPath)
    }

    /// Identifies mutations to the transactions registered for observers.
    ///
    /// This method calls ``willset(_:keypath:)`` before the mutation. Then it
    /// calls ``didset(_:keypath:)`` after the mutation.
    /// - Parameters:
    ///   - of: An instance of an observable type.
    ///   - keyPath: The key path of an observed property.
    func withMutation<Subject: Perceptible, T>(
        of subject: Subject,
        keyPath: KeyPath<Subject, some Any>,
        _ mutation: () throws -> T
    ) rethrows -> T {
        willSet(subject, keyPath: keyPath)
        defer { didSet(subject, keyPath: keyPath) }
        return try mutation()
    }
}
