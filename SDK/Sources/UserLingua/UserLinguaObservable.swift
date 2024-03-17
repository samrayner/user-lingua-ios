// UserLinguaObservable.swift

import Dependencies
import Spyable
import SwiftUI

@Spyable
protocol UserLinguaObservableProtocol: ObservableObject {
    func refresh()
}

public final class UserLinguaObservable: UserLinguaObservableProtocol {
    func refresh() {
        objectWillChange.send()
    }
}

enum UserLinguaObservableDependency: DependencyKey {
    static let liveValue: any UserLinguaObservableProtocol = UserLingua.shared.viewModel
    static let previewValue: any UserLinguaObservableProtocol = UserLinguaObservableProtocolSpy()
    static let testValue: any UserLinguaObservableProtocol = UserLinguaObservableProtocolSpy()
}
