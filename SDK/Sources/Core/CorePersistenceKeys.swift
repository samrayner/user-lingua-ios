// CorePersistenceKeys.swift

import ComposableArchitecture

extension InMemoryKey where Value == Configuration {
    package static var configuration: Self { .init(#function) }
}
