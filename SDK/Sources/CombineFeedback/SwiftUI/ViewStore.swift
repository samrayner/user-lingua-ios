// ViewStore.swift

import CasePaths
import Combine
import CombineSchedulers
import SwiftUI

@dynamicMemberLookup
public final class ViewStore<State, Event>: ObservableObject {
    @Published private var state: State
    private var bag = Set<AnyCancellable>()

    init(
        store: StoreBoxBase<State, Event>,
        removeDuplicates isDuplicate: @escaping (State, State) -> Bool
    ) {
        self.state = store.currentState
        store.publisher
            .removeDuplicates(by: isDuplicate)
            .receive(on: UIScheduler.shared, options: nil)
            .assign(to: \.state, weakly: self)
            .store(in: &bag)
    }

    public subscript<Value>(dynamicMember keyPath: KeyPath<State, Value>) -> Value {
        state[keyPath: keyPath]
    }

    public func publisher<Value>(for transform: @escaping (State) -> Value) -> AnyPublisher<Value, Never> {
        $state
            .map(transform)
            .eraseToAnyPublisher()
    }
}

public typealias ViewStoreOf<F: Feature> = ViewStore<F.State, F.Event>
