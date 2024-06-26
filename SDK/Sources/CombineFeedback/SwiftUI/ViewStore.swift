// ViewStore.swift

import CasePaths
import Combine
import CombineSchedulers
import SwiftUI

@dynamicMemberLookup
public final class ViewStore<State, Event>: ObservableObject {
    @Published public var state: State
    private var cancellables = Set<AnyCancellable>()

    init(
        store: StoreBoxBase<State, Event>,
        removeDuplicates isDuplicate: @escaping (State, State) -> Bool
    ) {
        self.state = store.currentState
        store.publisher
            .removeDuplicates(by: isDuplicate)
            .receive(on: UIScheduler.shared, options: nil)
            .assign(to: \.state, weakly: self)
            .store(in: &cancellables)
    }

    init<S>(
        store: StoreBoxBase<S, Event>,
        scope: @escaping (S) -> State
    ) where State: Equatable {
        self.state = scope(store.currentState)
        store.publisher
            .map(scope)
            .removeDuplicates()
            .receive(on: UIScheduler.shared, options: nil)
            .assign(to: \.state, weakly: self)
            .store(in: &cancellables)
    }

    public subscript<Value>(dynamicMember keyPath: KeyPath<State, Value>) -> Value {
        state[keyPath: keyPath]
    }
}

public typealias ViewStoreOf<F: Feature> = ViewStore<F.State, F.Event>
