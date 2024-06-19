// CorePersistenceKeys.swift

import ComposableArchitecture

extension PersistenceKey where Self == InMemoryKey<Configuration> {
    package static var configuration: Self {
        inMemory(#function)
    }
}
