// UserLinguaObservable.swift

import Combine

public final class UserLinguaObservable: ObservableObject {
    public init() {}

    public func refresh() {
        Task { @MainActor in
            objectWillChange.send()
        }
    }

    public var refreshPublisher: AnyPublisher<Void, Never> {
        objectWillChange.eraseToAnyPublisher()
    }
}
