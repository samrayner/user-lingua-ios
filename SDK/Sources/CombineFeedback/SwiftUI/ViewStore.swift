// ViewStore.swift

import CasePaths
import Combine
import CombineSchedulers
import SwiftUI

@dynamicMemberLookup
public final class ViewStore<State, Event>: ObservableObject {
    @Published private var state: State
    private var bag = Set<AnyCancellable>()
    private let send: (Event) -> Void

    init(
        store: StoreBoxBase<State, Event>,
        removeDuplicates isDuplicate: @escaping (State, State) -> Bool
    ) {
        self.state = store._current
        self.send = store.send
        store.publisher
            .removeDuplicates(by: isDuplicate)
            .receive(on: UIScheduler.shared, options: nil)
            .assign(to: \.state, weakly: self)
            .store(in: &bag)
    }

    public subscript<Value>(dynamicMember keyPath: KeyPath<State, Value>) -> Value {
        state[keyPath: keyPath]
    }

    public func send(_ event: Event) {
        send(event)
    }

    public func binding<Value>(
        get: @escaping (State) -> Value,
        send event: @escaping (Value) -> Event
    ) -> Binding<Value> {
        Binding(
            get: {
                get(self.state)
            },
            set: {
                self.send(event($0))
            }
        )
    }

    public func publisher<Value>(for transform: @escaping (State) -> Value) -> AnyPublisher<Value, Never> {
        $state
            .map(transform)
            .eraseToAnyPublisher()
    }
}

public typealias ViewStoreOf<F: Feature> = ViewStore<F.State, F.Event>
