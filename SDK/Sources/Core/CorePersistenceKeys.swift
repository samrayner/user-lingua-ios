// CorePersistenceKeys.swift

import ComposableArchitecture

extension PersistenceKey where Self == InMemoryKey<String> {
    package static var configuration: Self {
        inMemory(#function)
    }
}
