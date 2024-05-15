// NavigationID.swift

@_spi(Reflection) import CasePaths

extension DependencyValues {
    var navigationIDPath: NavigationIDPath {
        get { self[NavigationIDPathKey.self] }
        set { self[NavigationIDPathKey.self] = newValue }
    }
}

private enum NavigationIDPathKey: DependencyKey {
    static let liveValue = NavigationIDPath()
    static let testValue = NavigationIDPath()
}

@usableFromInline
struct NavigationIDPath: Hashable, Sendable {
    fileprivate var path: [NavigationID]

    init(path: [NavigationID] = []) {
        self.path = path
    }

    var prefixes: [NavigationIDPath] {
        (0 ... path.count).map { index in
            NavigationIDPath(path: Array(path.dropFirst(index)))
        }
    }

    func appending(_ element: NavigationID) -> Self {
        .init(path: path + [element])
    }

    public var id: Self { self }
}

struct NavigationID: Hashable, @unchecked Sendable {
    private let kind: Kind
    private let identifier: AnyHashableSendable?
    private let tag: UInt32?

    enum Kind: Hashable, @unchecked Sendable {
        case casePath(root: Any.Type, value: Any.Type)
        case keyPath(AnyKeyPath)

        static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case let (.casePath(lhsRoot, lhsValue), .casePath(rhsRoot, rhsValue)):
                lhsRoot == rhsRoot && lhsValue == rhsValue
            case let (.keyPath(lhs), .keyPath(rhs)):
                lhs == rhs
            case (.casePath, _), (.keyPath, _):
                false
            }
        }

        func hash(into hasher: inout Hasher) {
            switch self {
            case let .casePath(root: root, value: value):
                hasher.combine(0)
                hasher.combine(ObjectIdentifier(root))
                hasher.combine(ObjectIdentifier(value))
            case let .keyPath(keyPath):
                hasher.combine(1)
                hasher.combine(keyPath)
            }
        }
    }

    init<Value>(
        base: Value,
        keyPath: KeyPath<some Any, Value?>
    ) {
        self.kind = .keyPath(keyPath)
        self.tag = EnumMetadata(Value.self)?.tag(of: base)
        if let id = _identifiableID(base) ?? EnumMetadata.project(base).flatMap(_identifiableID) {
            self.identifier = AnyHashableSendable(id)
        } else {
            self.identifier = nil
        }
    }

    init(
        id: StackElementID,
        keyPath: KeyPath<some Any, StackState<some Any>>
    ) {
        self.kind = .keyPath(keyPath)
        self.tag = nil
        self.identifier = AnyHashableSendable(id)
    }

    init<ID: Hashable>(
        id: ID,
        keyPath: KeyPath<some Any, IdentifiedArray<ID, some Any>>
    ) {
        self.kind = .keyPath(keyPath)
        self.tag = nil
        self.identifier = AnyHashableSendable(id)
    }

    init<Value, Root>(
        root: Root,
        value: Value,
        casePath _: AnyCasePath<Root, Value>
    ) {
        self.kind = .casePath(root: Root.self, value: Value.self)
        self.tag = EnumMetadata(Root.self)?.tag(of: root)
        if let id = _identifiableID(root) ?? _identifiableID(value) {
            self.identifier = AnyHashableSendable(id)
        } else {
            self.identifier = nil
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.kind == rhs.kind
            && lhs.identifier == rhs.identifier
            && lhs.tag == rhs.tag
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(kind)
        hasher.combine(identifier)
        hasher.combine(tag)
    }
}

@_spi(Internals)
public struct AnyHashableSendable: Hashable, @unchecked Sendable {
    @_spi(Internals) public let base: AnyHashable
    init(_ base: some Hashable & Sendable) {
        self.base = base
    }
}
