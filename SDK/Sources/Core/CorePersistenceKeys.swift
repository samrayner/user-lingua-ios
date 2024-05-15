// CorePersistenceKeys.swift

import ComposableArchitecture

extension InMemoryKey where Value == Configuration {
    public static var configuration: Self { .init(#function) }
}
