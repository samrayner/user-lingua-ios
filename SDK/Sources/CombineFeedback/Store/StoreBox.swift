// StoreBox.swift

import CasePaths
import Combine
import SwiftUI

class RootStoreBox<State, Event>: StoreBoxBase<State, Event> {
    private let subject: CurrentValueSubject<State, Never>

    private let inputObserver: (Event) -> Void
    private var bag = Set<AnyCancellable>()

    override var _current: State {
        subject.value
    }

    override var publisher: AnyPublisher<State, Never> {
        subject.eraseToAnyPublisher()
    }

    public init<Dependencies>(
        initial: State,
        feedbacks: [Feedback<State, Event, Dependencies>],
        reducer: Reducer<State, Event>,
        dependencies: Dependencies
    ) {
        let input = Feedback<State, Event, Dependencies>.input
        self.subject = CurrentValueSubject(initial)
        self.inputObserver = input.observer
        Publishers.FeedbackLoop(
            initial: initial,
            reduce: reducer,
            feedbacks: feedbacks
                .appending(input.feedback),
            dependencies: dependencies
        )
        .sink(receiveValue: { [subject] state in
            subject.send(state)
        })
        .store(in: &bag)
    }

    override func send(event: Event) {
        inputObserver(event)
    }

    override func scoped<S, E>(
        getValue: @escaping (State) -> S,
        event: @escaping (E) -> Event
    ) -> StoreBoxBase<S, E> {
        ScopedStoreBox<State, Event, S, E>(
            parent: self,
            getValue: getValue,
            event: event
        )
    }
}

class ScopedStoreBox<RootState, RootEvent, ScopedState, ScopedEvent>: StoreBoxBase<ScopedState, ScopedEvent> {
    private let parent: StoreBoxBase<RootState, RootEvent>
    private let getValue: (RootState) -> ScopedState
    private let eventTransform: (ScopedEvent) -> RootEvent

    override var _current: ScopedState {
        getValue(parent._current)
    }

    override var publisher: AnyPublisher<ScopedState, Never> {
        parent.publisher.map(getValue).eraseToAnyPublisher()
    }

    init(
        parent: StoreBoxBase<RootState, RootEvent>,
        getValue: @escaping (RootState) -> ScopedState,
        event: @escaping (ScopedEvent) -> RootEvent
    ) {
        self.parent = parent
        self.getValue = getValue
        self.eventTransform = event
    }

    override func send(event: ScopedEvent) {
        parent.send(event: eventTransform(event))
    }

    override func scoped<S, E>(
        getValue: @escaping (ScopedState) -> S,
        event: @escaping (E) -> ScopedEvent
    ) -> StoreBoxBase<S, E> {
        ScopedStoreBox<RootState, RootEvent, S, E>(
            parent: parent
        ) { rootState in
            getValue(self.getValue(rootState))
        } event: { e in
            self.eventTransform(event(e))
        }
    }
}

class StoreBoxBase<State, Event> {
    /// Loop Internal SPI
    var _current: State { subclassMustImplement() }

    var publisher: AnyPublisher<State, Never> { subclassMustImplement() }

    func send(event _: Event) {
        subclassMustImplement()
    }

    final func scoped<S, E>(
        to scope: WritableKeyPath<State, S>,
        event: @escaping (E) -> Event
    ) -> StoreBoxBase<S, E> {
        scoped(
            getValue: { state in
                state[keyPath: scope]
            },
            event: event
        )
    }

    func scoped<S, E>(
        getValue _: @escaping (State) -> S,
        event _: @escaping (E) -> Event
    ) -> StoreBoxBase<S, E> {
        subclassMustImplement()
    }
}

@inline(never)
private func subclassMustImplement(function: StaticString = #function) -> Never {
    fatalError("Subclass must implement `\(function)`.")
}
