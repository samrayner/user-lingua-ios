// UserLinguaObservable.swift

import Combine
import Dependencies
import Spyable

@Spyable
protocol UserLinguaObservableProtocol: ObservableObject {
    func refresh()
    var refreshPublisher: AnyPublisher<Void, Never> { get }
}

public final class UserLinguaObservable: UserLinguaObservableProtocol {
    func refresh() {
        objectWillChange.send()
    }

    var refreshPublisher: AnyPublisher<Void, Never> {
        objectWillChange.eraseToAnyPublisher()
    }
}

enum UserLinguaObservableDependency: DependencyKey {
    static let liveValue: any UserLinguaObservableProtocol = UserLingua.shared.viewModel
    static let previewValue: any UserLinguaObservableProtocol = UserLinguaObservableProtocolSpy()
    static let testValue: any UserLinguaObservableProtocol = UserLinguaObservableProtocolSpy()
}
