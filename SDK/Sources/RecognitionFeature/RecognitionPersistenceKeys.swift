// RecognitionPersistenceKeys.swift

import ComposableArchitecture

extension InMemoryKey where Value == RecognitionFeature.State {
    public static var recognitionState: Self { .init(#function) }
}
