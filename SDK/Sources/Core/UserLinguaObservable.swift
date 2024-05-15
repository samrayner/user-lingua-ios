// UserLinguaObservable.swift

import Combine
import Dependencies

// sourcery: AutoMockable
public protocol UserLinguaObservableProtocol: ObservableObject {
    func refresh()
    var refreshPublisher: AnyPublisher<Void, Never> { get }
}

public final class UserLinguaObservable: UserLinguaObservableProtocol {
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

public enum UserLinguaObservableDependency: DependencyKey {
    public static let liveValue: any UserLinguaObservableProtocol = UserLinguaObservable()
    public static let previewValue: any UserLinguaObservableProtocol = UserLinguaObservableProtocolMock()
    public static let testValue: any UserLinguaObservableProtocol = UserLinguaObservableProtocolMock()
}
