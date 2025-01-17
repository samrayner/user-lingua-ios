// StoreBox.swift

import CasePaths
import Combine
import SwiftUI

class RootStoreBox<State, Event>: StoreBoxBase<State, Event> {
    private let subject: CurrentValueSubject<State, Never>

    private let inputObserver: (Event) -> Void
    private var bag = Set<AnyCancellable>()

    override var currentState: State {
        subject.value
    }

    override var publisher: AnyPublisher<State, Never> {
        subject.eraseToAnyPublisher()
    }

    init<Dependencies>(
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

    override var currentState: ScopedState {
        getValue(parent.currentState)
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
        event scopeEvent: @escaping (E) -> ScopedEvent
    ) -> StoreBoxBase<S, E> {
        ScopedStoreBox<RootState, RootEvent, S, E>(
            parent: parent
        ) { rootState in
            getValue(self.getValue(rootState))
        } event: { event in
            self.eventTransform(scopeEvent(event))
        }
    }
}

class StoreBoxBase<State, Event> {
    var currentState: State { subclassMustImplement() }

    var publisher: AnyPublisher<State, Never> { subclassMustImplement() }

    func send(event _: Event) {
        subclassMustImplement()
    }

    final func scoped<S, E>(
        to scope: @escaping (State) -> S,
        event: @escaping (E) -> Event
    ) -> StoreBoxBase<S, E> {
        scoped(
            getValue: { state in
                scope(state)
            },
            event: event
        )
    }

    func scoped<S, E>(
        optional scope: @escaping (State) -> S?,
        event: @escaping (E) -> Event
    ) -> StoreBoxBase<S, E>? {
        guard let childState = scope(currentState) else { return nil }
        return scoped(
            getValue: { state in
                scope(state) ?? childState
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
