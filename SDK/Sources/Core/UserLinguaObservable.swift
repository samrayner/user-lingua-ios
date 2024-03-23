// UserLinguaObservable.swift

import Combine
import Dependencies
import Spyable
import UIKit

@Spyable
package protocol UserLinguaObservableProtocol: ObservableObject {
    @discardableResult
    func refresh() -> Task<Void, Never>
    var refreshPublisher: AnyPublisher<Void, Never> { get }
}

public final class UserLinguaObservable: UserLinguaObservableProtocol {
    package init() {}

    @discardableResult
    package func refresh() -> Task<Void, Never> {
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
    package static let previewValue: any UserLinguaObservableProtocol = UserLinguaObservableProtocolSpy()
    package static let testValue: any UserLinguaObservableProtocol = UserLinguaObservableProtocolSpy()
}
