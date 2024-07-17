// Store.swift

import CasePaths
import Combine
import Foundation
import SwiftUI

open class Store<State, Event> {
    private let box: StoreBoxBase<State, Event>
    private let eventSubject: PassthroughSubject<Event, Never> = .init()

    public var state: State {
        box.currentState
    }

    var publisher: AnyPublisher<State, Never> {
        box.publisher
    }

    init(box: StoreBoxBase<State, Event>) {
        self.box = box
    }

    public init<Dependencies>(
        initialState: State,
        feedbacks: [Feedback<State, Event, Dependencies>],
        reducer: Reducer<State, Event>,
        dependencies: Dependencies
    ) {
        self.box = RootStoreBox(
            initial: initialState,
            feedbacks: feedbacks,
            reducer: reducer,
            dependencies: dependencies
        )
    }

    @MainActor
    func viewStore(
        removingDuplicates isDuplicate: @escaping (State, State) -> Bool
    ) -> ViewStore<State, Event> {
        ViewStore(store: box, removingDuplicates: isDuplicate)
    }

    @MainActor
    func viewStore<S: Equatable>(
        scoped scope: @escaping (State) -> S
    ) -> ViewStore<S, Event> {
        ViewStore(store: box, scoped: scope)
    }

    open func send(_ event: Event) {
        box.send(event: event)
        eventSubject.send(event)
    }

    public func scoped<S>(
        to scope: @escaping (State) -> S
    ) -> Store<S, Event> {
        Store<S, Event>(
            box: box.scoped(getValue: scope, event: { $0 })
        )
    }

    public func scoped<S, E>(
        to scope: @escaping (State) -> S,
        event: @escaping (E) -> Event
    ) -> Store<S, E> {
        Store<S, E>(box: box.scoped(to: scope, event: event))
    }

    public func scoped<S, E>(
        to scope: @escaping (State) -> S?,
        event: @escaping (E) -> Event
    ) -> Store<S, E>? {
        box.scoped(optional: scope, event: event).map(Store<S, E>.init(box:))
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

    public func publisher<Value>(for scope: @escaping (State) -> Value) -> AnyPublisher<Value, Never> {
        publisher
            .map(scope)
            .eraseToAnyPublisher()
    }
}

extension Array {
    func appending(_ element: Element) -> [Element] {
        var copy = self

        copy.append(element)

        return copy
    }
}

extension Publisher where Self.Failure == Never {
    public func assign<Root: AnyObject>(
        to keyPath: WritableKeyPath<Root, Self.Output>, weakly object: Root
    ) -> AnyCancellable {
        sink { [weak object] output in
            object?[keyPath: keyPath] = output
        }
    }
}

public typealias StoreOf<F: Feature> = Store<F.State, F.Event>

extension Store: Equatable {
    public static func == (lhs: Store, rhs: Store) -> Bool {
        lhs === rhs
    }
}

extension Store: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

extension Store: Identifiable {}
