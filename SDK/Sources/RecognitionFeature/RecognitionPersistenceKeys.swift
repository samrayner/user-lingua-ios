// RecognitionPersistenceKeys.swift

import ComposableArchitecture

extension PersistenceKey where Self == InMemoryKey<RecognitionFeature.State> {
    package static var recognitionState: Self {
        inMemory(#function)
    }
}
