// Store.swift

import CasePaths
import Combine
import Foundation

@dynamicMemberLookup
open class Store<State, Event> {
    private let box: StoreBoxBase<State, Event>

    public var state: State {
        box._current
    }

    var publisher: AnyPublisher<State, Never> {
        box.publisher
    }

    init(box: StoreBoxBase<State, Event>) {
        self.box = box
    }

    public init<Dependencies>(
        initial: State,
        feedbacks: [Feedback<State, Event, Dependencies>],
        reducer: Reducer<State, Event>,
        dependencies: Dependencies
    ) {
        self.box = RootStoreBox(
            initial: initial,
            feedbacks: feedbacks,
            reducer: reducer,
            dependencies: dependencies
        )
    }

    @MainActor
    func viewStore(
        removeDuplicates isDuplicate: @escaping (State, State) -> Bool
    ) -> ViewStore<State, Event> {
        ViewStore(store: box, removeDuplicates: isDuplicate)
    }

    open func send(_ event: Event) {
        box.send(event: event)
    }

    public func scope<S>(
        getValue: @escaping (State) -> S
    ) -> Store<S, Event> {
        Store<S, Event>(
            box: box.scoped(getValue: getValue, event: { $0 })
        )
    }

    public func scope<S, E>(
        getValue: @escaping (State) -> S,
        event: @escaping (E) -> Event
    ) -> Store<S, E> {
        Store<S, E>(
            box: box.scoped(getValue: getValue, event: event)
        )
    }

    public func scoped<S, E>(
        to scope: WritableKeyPath<State, S>,
        event: @escaping (E) -> Event
    ) -> Store<S, E> {
        Store<S, E>(box: box.scoped(to: scope, event: event))
    }

    public subscript<U>(dynamicMember keyPath: KeyPath<State, U>) -> U {
        state[keyPath: keyPath]
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
