// Feedback.swift

import CasePaths
import Combine
import SwiftUI
import Utilities

public struct Feedback<State, Event, Dependencies> {
    public struct Effect {
        public static func send(_ event: Event) -> Self {
            .init(
                Just(event).eraseToAnyPublisher()
            )
        }

        public static func send(_ event: Event, after delay: TimeInterval) -> Self {
            .init(
                Just(event)
                    .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
                    .eraseToAnyPublisher()
            )
        }

        public static func combine(_ effect: Effect...) -> Self {
            .init(
                Publishers.MergeMany(effect.map(\.publisher)).eraseToAnyPublisher()
            )
        }

        public static var none: Self {
            .init(Empty().eraseToAnyPublisher())
        }

        public static func publish(_ publisher: AnyPublisher<Event, Never>) -> Self {
            .init(publisher)
        }

        let publisher: AnyPublisher<Event, Never>

        private init(_ publisher: AnyPublisher<Event, Never>) {
            self.publisher = publisher
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
    /// state changes.
    ///
    /// If the previous effect is still alive when a new one is about to start,
    /// the previous one would automatically be cancelled.
    ///
    /// - parameters:
    ///   - scope: The transform to apply on the state.
    ///   - removingDuplicates
    ///   - effects: The side effect accepting transformed values produced by
    ///              `scope` and yielding events that eventually affect
    ///              the state.
    public static func state<ScopedState: Equatable>(
        scoped scope: @escaping (State) -> ScopedState,
        ifChanged equalityTransform: ((ScopedState) -> some Equatable)?,
        effect: @escaping ((old: ScopedState, new: ScopedState), Dependencies) -> Effect
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
                .onlyWithPrevious() // we don't care about the initial state anyway
                .compactMap { previous, current -> (ScopedState, ScopedState)? in
                    // ignore subsequent initial states
                    // Note: maybe a bug keeping state Feedback publishers subscribed
                    // even after the feature they observe has been deallocated?
                    guard current.event != nil else { return nil }
                    return (previous.state, current.state)
                }
                .flatMapLatest { oldState, newState in
                    effect((oldState, newState), dependencies)
                        .publisher
                        .enqueue(to: output)
                }
        }
    }

    public static func state<ScopedState: Equatable>(
        scoped scope: @escaping (State) -> ScopedState,
        effect: @escaping ((old: ScopedState, new: ScopedState), Dependencies) -> Effect
    ) -> Feedback {
        state(scoped: scope, ifChanged: { $0 }, effect: effect)
    }

    public static func state(
        ifChanged equalityTransform: ((State) -> some Equatable)?,
        effect: @escaping ((old: State, new: State), Dependencies) -> Effect
    ) -> Feedback where State: Equatable {
        state(scoped: { $0 }, ifChanged: equalityTransform, effect: effect)
    }

    public static func state(
        effect: @escaping ((old: State, new: State), Dependencies) -> Effect
    ) -> Feedback where State: Equatable {
        state(ifChanged: { $0 }, effect: effect)
    }

    public static func event<Payload>(
        _ extract: @escaping (Event) -> Payload?,
        effect: @escaping (Payload, (old: State, new: State), Dependencies) -> Effect
    ) -> Feedback {
        custom { input, output, dependencies in
            // NOTE: `observe(on:)` should be applied on the inner producers, so
            //       that cancellation due to state changes would be able to
            //       cancel outstanding events that have already been scheduled.
            input
                // if in future we want to cancel in-progress event feedbacks when
                // when the same event fires before completion, we can add
                // .removeDuplicates {
                //    $0.1 != $1.1
                // }
                // here and make flatMap below flatMapLatest. This is the method by
                // which state changes cancel feedback for changes of the same state.
                .onlyWithPrevious() // the first emission always has a nil event anyway
                .compactMap { previous, current -> (Payload?, State, State)? in
                    guard let event = current.1 else { return nil }
                    return (extract(event), previous.0, current.0)
                }
                .flatMap { payload, oldState, newState in
                    let publisher = if let payload {
                        effect(payload, (oldState, newState), dependencies).publisher
                    } else {
                        Empty<Event, Never>().eraseToAnyPublisher()
                    }
                    return publisher.enqueue(to: output)
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

    public static func combine(_ feedbacks: [Feedback]) -> Feedback {
        Feedback { state, consumer, dependencies -> Cancellable in
            feedbacks.map { feedback -> Cancellable in
                feedback.events(state, consumer, dependencies)
            }
        }
    }

    public static func combine(_ feedbacks: Feedback...) -> Feedback {
        combine(feedbacks)
    }

    static var input: (feedback: Feedback, observer: (Event) -> Void) {
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

extension [Cancellable]: @retroactive Cancellable {
    public func cancel() {
        for element in self {
            element.cancel()
        }
    }
}

public typealias FeedbackOf<F: Feature> = Feedback<F.State, F.Event, F.Dependencies>
