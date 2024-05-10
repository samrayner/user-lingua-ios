// UserLinguaObservable.swift

import Combine
import Dependencies

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

package enum UserLinguaObservableDependency: DependencyKey {
    package static let liveValue: any UserLinguaObservableProtocol = UserLinguaObservable()
    package static let previewValue: any UserLinguaObservableProtocol = UserLinguaObservableProtocolMock()
    package static let testValue: any UserLinguaObservableProtocol = UserLinguaObservableProtocolMock()
}
