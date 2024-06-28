// Feedback.swift

import CasePaths
import Combine
import CombineSchedulers
import SwiftUI

public struct Feedback<State, Event, Dependencies> {
    public enum Effect {
        public static func send(_ event: Event, after delay: TimeInterval? = nil) -> Self {
            .send([event], after: delay)
        }

        case publish(AnyPublisher<Event, Never>)
        case send([Event], after: TimeInterval? = nil)
        case none

        var publisher: AnyPublisher<Event, Never> {
            switch self {
            case let .publish(publisher):
                publisher
            case let .send(events, delayInterval):
                if let delayInterval {
                    events.publisher
                        .delay(for: .seconds(delayInterval), scheduler: UIScheduler.shared)
                        .eraseToAnyPublisher()
                } else {
                    events.publisher.eraseToAnyPublisher()
                }
            case .none:
                Empty().eraseToAnyPublisher()
            }
        }
    }

    public let events: (
        _ state: AnyPublisher<(State, Event?), Never>,
        _ output: FeedbackEventConsumer<Event>,
        _ dependencies: Dependencies
    ) -> Cancellable

    init(events: @escaping (
        _ state: AnyPublisher<(State, Event?), Never>,
        _ output: FeedbackEventConsumer<Event>,
        _ dependencies: Dependencies
    ) -> Cancellable) {
        self.events = events
    }

    /// Creates a custom Feedback, with the complete liberty of defining the data flow.
    ///
    /// - important: While you may respond to state changes in whatever ways you prefer, you **must** enqueue produced
    ///              events using the `Publisher.enqueue(to:)` operator to the `FeedbackEventConsumer` provided
    ///              to you. Otherwise, the feedback loop will not be able to pick up and process your events.
    ///
    /// - parameters:
    ///   - setup: The setup closure to construct a data flow producing events in respond to changes from `state`,
    ///             and having them consumed by `output` using the `SignalProducer.enqueue(to:)` operator.
    private static func custom<P: Publisher>(
        _ setup: @escaping (
            _ state: AnyPublisher<(State, Event?), Never>,
            _ output: FeedbackEventConsumer<Event>,
            _ dependencies: Dependencies
        ) -> P
    ) -> Feedback where P.Failure == Never, P.Output == Never {
        Feedback { state, output, dependencies -> Cancellable in
            setup(state, output, dependencies).start()
        }
    }

    /// Creates a Feedback which re-evaluates the given effect every time the
    /// `Signal` derived from the latest state yields a new value.
    ///
    /// If the previous effect is still alive when a new one is about to start,
    /// the previous one would automatically be cancelled.
    ///
    /// - parameters:
    ///   - transform: The transform which derives a `Signal` of values from the
    ///                latest state.
    ///   - effects: The side effect accepting transformed values produced by
    ///              `transform` and yielding events that eventually affect
    ///              the state.
    private static func compacting<U>(
        state scope: @escaping (AnyPublisher<State, Never>) -> AnyPublisher<U, Never>,
        effects: @escaping (U, Dependencies) -> AnyPublisher<Event, Never>
    ) -> Feedback {
        custom { input, output, dependencies in
            // NOTE: `observe(on:)` should be applied on the inner producers, so
            //       that cancellation due to state changes would be able to
            //       cancel outstanding events that have already been scheduled.
            scope(
                input
                    .map(\.0)
                    .eraseToAnyPublisher()
            )
            .flatMapLatest { scopedState in
                effects(scopedState, dependencies).enqueue(to: output)
            }
        }
    }

    private static func compacting<Payload>(
        events extract: @escaping (AnyPublisher<(Event, State), Never>) -> AnyPublisher<(Payload, State), Never>,
        effects: @escaping (Payload, State, Dependencies) -> AnyPublisher<Event, Never>
    ) -> Feedback {
        custom { input, output, dependencies in
            // NOTE: `observe(on:)` should be applied on the inner producers, so
            //       that cancellation due to state changes would be able to
            //       cancel outstanding events that have already been scheduled.
            extract(
                input
                    .compactMap { state, event -> (Event, State)? in
                        guard let event else { return nil }
                        return (event, state)
                    }
                    .eraseToAnyPublisher()
            )
            .flatMapLatest { payload, state in
                effects(payload, state, dependencies).enqueue(to: output)
            }
        }
    }

    /// Creates a Feedback which re-evaluates the given effect every time the
    /// state changes.
    ///
    /// If the previous effect is still alive when a new one is about to start,
    /// the previous one would automatically be cancelled.
    ///
    /// - parameters:
    ///   - transform: The transform to apply on the state.
    ///   - effects: The side effect accepting transformed values produced by
    ///              `transform` and yielding events that eventually affect
    ///              the state.
    public static func state<ScopedState: Equatable>(
        _ scope: @escaping (State) -> ScopedState,
        removeDuplicates equalityTransform: ((ScopedState) -> some Equatable)?,
        effects: @escaping (ScopedState, ScopedState, Dependencies) -> Effect
    ) -> Feedback {
        custom { input, output, dependencies in
            // NOTE: `observe(on:)` should be applied on the inner producers, so
            //       that cancellation due to state changes would be able to
            //       cancel outstanding events that have already been scheduled.
            input
                .map { state, event in
                    (state: scope(state), event: event)
                }
                .removeDuplicates {
                    if let equalityTransform {
                        equalityTransform($0.state) == equalityTransform($1.state)
                    } else {
                        false
                    }
                }
                .onlyWithPrevious() // ignore first initial state
                .compactMap { previous, current -> (ScopedState, ScopedState)? in
                    // ignore subsequent initial states
                    // Note: maybe a bug keeping state Feedback publishers subscribed
                    // even after the feature they observe has been deallocated?
                    guard current.event != nil else { return nil }
                    return (previous.state, current.state)
                }
                .flatMapLatest { oldState, newState in
                    effects(oldState, newState, dependencies)
                        .publisher
                        .enqueue(to: output)
                }
        }
    }

    public static func state<ScopedState: Equatable>(
        _ scope: @escaping (State) -> ScopedState,
        effects: @escaping (ScopedState, ScopedState, Dependencies) -> Effect
    ) -> Feedback {
        state(scope, removeDuplicates: { $0 }, effects: effects)
    }

    public static func state(
        removeDuplicates equalityTransform: ((State) -> some Equatable)?,
        effects: @escaping (State, State, Dependencies) -> Effect
    ) -> Feedback where State: Equatable {
        state({ $0 }, removeDuplicates: equalityTransform, effects: effects)
    }

    public static func state(
        effects: @escaping (State, State, Dependencies) -> Effect
    ) -> Feedback where State: Equatable {
        state(removeDuplicates: { $0 }, effects: effects)
    }

    /// Creates a Feedback which re-evaluates the given effect every time the
    /// given predicate passes.
    ///
    /// If the previous effect is still alive when a new one is about to start,
    /// the previous one would automatically be cancelled.
    ///
    /// - parameters:
    ///   - predicate: The predicate to apply on the state.
    ///   - effects: The side effect accepting the state and yielding events
    ///              that eventually affect the state.
    public static func state(
        predicate: @escaping (State) -> Bool,
        effects: @escaping (State, Dependencies) -> Effect
    ) -> Feedback {
        state(
            firstNonNil: { predicate($0) ? $0 : nil },
            effects: effects
        )
    }

    /// Creates a Feedback which re-evaluates the given effect every time the
    /// state changes.
    ///
    /// If the previous effect is still alive when a new one is about to start,
    /// the previous one would automatically be cancelled.
    ///
    /// - parameters:
    ///   - transform: The transform to apply on the state.
    ///   - effects: The side effect accepting transformed values produced by
    ///              `transform` and yielding events that eventually affect
    ///              the state.
    public static func event<Payload>(
        _ extract: @escaping (Event) -> Payload?,
        effects: @escaping (Payload, State, Dependencies) -> Effect
    ) -> Feedback {
        compacting(
            events: { events in
                events
                    .map { event, state in
                        (extract(event), state)
                    }
                    .eraseToAnyPublisher()
            },
            effects: { extractedPayload, state, dependencies in
                extractedPayload.map { effects($0, state, dependencies).publisher } ?? Empty().eraseToAnyPublisher()
            }
        )
    }

    public static func state<Value>(
        firstNonNil transform: @escaping (State) -> Value?,
        effects: @escaping (Value, Dependencies) -> Effect
    ) -> Feedback {
        .compacting(
            state: { state -> AnyPublisher<NilEdgeTransition<Value>, Never> in
                state.scan((lastWasNil: true, output: NilEdgeTransition<Value>?.none)) { acum, state in
                    var temp = acum
                    let result = transform(state)
                    temp.output = nil

                    switch (temp.lastWasNil, result) {
                    case (true, .none), (false, .some):
                        return temp
                    case let (true, .some(value)):
                        temp.lastWasNil = false
                        temp.output = .populated(value)
                    case (false, .none):
                        temp.lastWasNil = true
                        temp.output = .cleared
                    }
                    return temp
                }
                .compactMap(\.output)
                .eraseToAnyPublisher()
            },
            effects: { transition, dependencies in
                switch transition {
                case let .populated(value):
                    effects(value, dependencies).publisher
                case .cleared:
                    Empty().eraseToAnyPublisher()
                }
            }
        )
    }

    /// Redux like Middleware signature Feedback factory method that lets you perform side effects when state changes, also knowing which
    /// event cased it
    ///
    /// If the previous effect is still alive when a new one is about to start,
    /// the previous one would automatically be cancelled.
    ///
    /// Important: State value is coming after reducer with an Event that caused the mutation
    ///
    /// - parameters:
    ///   - effects: The side effect accepting the state and yielding events
    ///              that eventually affect the state.
    public static func any(
        _ effects: @escaping (State, Event?, Dependencies) -> Effect
    ) -> Feedback {
        custom { input, output, dependencies in
            input
                .compactMap { state, event -> (State, Event)? in
                    // filter out initial state (nil event)
                    guard let event else { return nil }
                    return (state, event)
                }
                .flatMapLatest {
                    effects($0, $1, dependencies)
                        .publisher
                        .enqueue(to: output)
                }
        }
    }
}

extension Feedback {
    /// Transforms a Feedback that works on local state, event, and dependencies into one that works on
    /// global state, action and dependencies. It accomplishes this by providing 3 transformations to
    /// the method:
    ///
    ///   * A key path that can get a piece of local state from the global state.
    ///   * A case path that can extract/embed a local event into a global event.
    ///   * A function that can transform the global dependencies into a local dependencies.
    public func pullback<GlobalState, GlobalEvent, GlobalDependencies>(
        state stateKeyPath: KeyPath<GlobalState, State>,
        event eventCasePath: CasePath<GlobalEvent, Event>,
        dependencies toLocal: @escaping (GlobalDependencies) -> Dependencies
    ) -> Feedback<GlobalState, GlobalEvent, GlobalDependencies> {
        return Feedback<GlobalState, GlobalEvent, GlobalDependencies>(events: { state, consumer, dependencies in
            let state = state.map {
                ($0[keyPath: stateKeyPath], $1.flatMap(eventCasePath.extract(from:)))
            }.eraseToAnyPublisher()
            return self.events(
                state,
                consumer.pullback(eventCasePath.embed),
                toLocal(dependencies)
            )
        })
    }

    /// Transforms a Feedback that works on local state, event, and dependencies into one that works on
    /// global state, action and dependencies. It accomplishes this by providing 3 transformations to
    /// the method:
    ///
    /// An application may model parts of its state with enums. For example, app state may differ if a
    /// user is logged-in or not:
    ///
    /// ```swift
    /// enum AppState {
    ///   case loggedIn(LoggedInState)
    ///   case loggedOut(LoggedOutState)
    /// }
    /// ```
    ///
    ///   * A case path that can extract/embed a local state into a global state.
    ///   * A case path that can extract/embed a local event into a global event.
    ///   * A function that can transform the global dependencies into a local dependencies.
    public func pullback<GlobalState, GlobalEvent, GlobalDependencies>(
        state stateCasePath: CasePath<GlobalState, State>,
        event eventCasePath: CasePath<GlobalEvent, Event>,
        dependencies toLocal: @escaping (GlobalDependencies) -> Dependencies
    ) -> Feedback<GlobalState, GlobalEvent, GlobalDependencies> {
        return Feedback<GlobalState, GlobalEvent, GlobalDependencies>(events: { state, consumer, dependencies in
            let state: AnyPublisher<(State, Event?), Never> = state.compactMap { (stateAndEvent: (
                GlobalState,
                GlobalEvent?
            )) -> (State, Event?)? in
                guard let localState = stateCasePath.extract(from: stateAndEvent.0) else {
                    return nil
                }
                return (localState, stateAndEvent.1.flatMap(eventCasePath.extract(from:)))
            }.eraseToAnyPublisher()
            return self.events(
                state,
                consumer.pullback(eventCasePath.embed),
                toLocal(dependencies)
            )
        })
    }

    public static func combine(
        _ feedbacks: Feedback...
    ) -> Feedback {
        Feedback { state, consumer, dependencies -> Cancellable in
            feedbacks.map { feedback -> Cancellable in
                feedback.events(state, consumer, dependencies)
            }
        }
    }

    public static var input: (feedback: Feedback, observer: (Event) -> Void) {
        let subject = PassthroughSubject<Event, Never>()
        let feedback = Feedback.custom { _, consumer, _ in
            subject.enqueue(to: consumer)
        }
        return (feedback, subject.send)
    }
}

extension Feedback {
    public func optional() -> Feedback<State?, Event, Dependencies> {
        Feedback<State?, Event, Dependencies> { input, output, dependencies in
            self.events(
                input
                    .compactMap { state, event -> (State, Event?)? in
                        guard let state else { return nil }
                        return (state, event)
                    }
                    .eraseToAnyPublisher(),
                output,
                dependencies
            )
        }
    }
}

extension [Cancellable]: Cancellable {
    public func cancel() {
        for element in self {
            element.cancel()
        }
    }
}

private enum NilEdgeTransition<Value> {
    case populated(Value)
    case cleared
}

public typealias FeedbackOf<F: Feature> = Feedback<F.State, F.Event, F.Dependencies>
