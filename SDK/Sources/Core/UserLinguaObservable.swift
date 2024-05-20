// UserLinguaObservable.swift

import Combine

// sourcery: AutoMockable
package protocol UserLinguaObservableProtocol: ObservableObject {
    func refresh()
    var refreshPublisher: AnyPublisher<Void, Never> { get }
}

public final class UserLinguaObservable: UserLinguaObservableProtocol {
    package init() {}

    package func refresh() {
        Task { @MainActor in
            objectWillChange.send()
        }
    }

    package var refreshPublisher: AnyPublisher<Void, Never> {
        objectWillChange.eraseToAnyPublisher()
    }
}
