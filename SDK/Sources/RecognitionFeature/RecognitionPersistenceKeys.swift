// RecognitionPersistenceKeys.swift

import Lib_ComposableArchitecture

extension InMemoryKey where Value == RecognitionFeature.State {
    package static var recognitionState: Self { .init(#function) }
}
