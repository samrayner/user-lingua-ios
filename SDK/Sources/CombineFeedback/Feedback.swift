// Feedback.swift

import CasePaths
import Combine

public struct Feedback<State, Event, Dependencies> {
    public enum Effect {
        public static func send(_ events: Event...) -> Self {
            .send(events)
        }

        case publish(AnyPublisher<Event, Never>)
        case send([Event])
        case none

        var publisher: AnyPublisher<Event, Never> {
            switch self {
            case let .publish(publisher):
                publisher
            case let .send(events):
                events.publisher.eraseToAnyPublisher()
            case .none:
                Empty().eraseToAnyPublisher()
            }
        }
    }

    public let events: (
        _ input: AnyPublisher<(State, Event?), Never>,
        _ output: FeedbackEventConsumer<Event>,
        _ dependencies: Dependencies
    ) -> Cancellable

    init(events: @escaping (
        _ input: AnyPublisher<(State, Event?), Never>,
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
            _ input: AnyPublisher<(State, Event?), Never>,
            _ output: FeedbackEventConsumer<Event>,
            _ dependencies: Dependencies
        ) -> P
    ) -> Feedback where P.Failure == Never, P.Output == Never {
        Feedback { input, output, dependencies -> Cancellable in
            setup(input, output, dependencies).start()
        }
    }

    private static func compacting<TransformedInput, EventsPublisher: Publisher>(
        input flatMapInput: @escaping (AnyPublisher<(State, Event?), Never>) -> AnyPublisher<TransformedInput, Never>,
        events: @escaping (TransformedInput, Dependencies) -> EventsPublisher
    ) -> Feedback where EventsPublisher.Output == Event, EventsPublisher.Failure == Never {
        custom { input, output, dependencies in
            // NOTE: `observe(on:)` should be applied on the inner producers, so
            //       that cancellation due to state changes would be able to
            //       cancel outstanding events that have already been scheduled.
            flatMapInput(input)
                .flatMapLatest { events($0, dependencies).enqueue(to: output) }
        }
    }

    /// Creates a Feedback which re-evaluates the given effect every time the
    /// state changes.
    ///
    /// If the previous effect is still alive when a new one is about to start,
    /// the previous one would automatically be cancelled.
    public static func state<Value: Equatable>(
        _ scope: @escaping (State) -> Value,
        removeDuplicates: Bool = true,
        effect: @escaping (Value, State, Dependencies) -> Effect
    ) -> Feedback {
        compacting(
            input: {
                let scoped = $0.map { state, event in
                    (value: scope(state), state: state, event: event)
                }

                if removeDuplicates {
                    return scoped
                        .removeDuplicates { $0.value == $1.value }
                        .eraseToAnyPublisher()
                } else {
                    return scoped.eraseToAnyPublisher()
                }
            },
            events: { input, dependencies -> AnyPublisher<Event, Never> in
                effect(input.value, input.state, dependencies)
                    .publisher
                    .eraseToAnyPublisher()
            }
        )
    }

    /// Creates a Feedback which re-evaluates the given effect every time the
    /// state changes.
    ///
    /// If the previous effect is still alive when a new one is about to start,
    /// the previous one would automatically be cancelled.
    public static func state(
        removeDuplicates: Bool = true,
        effect: @escaping (State, Dependencies) -> Effect
    ) -> Feedback where State: Equatable {
        state(
            { $0 },
            removeDuplicates: removeDuplicates,
            effect: { _, state, dependencies in
                effect(state, dependencies)
            }
        )
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
        effect: @escaping (State, Dependencies) -> Effect
    ) -> Feedback {
        firstValueAfterNil(
            { state -> State? in
                predicate(state) ? state : nil
            },
            events: { state, dependencies -> AnyPublisher<Event, Never> in
                effect(state, dependencies)
                    .publisher
                    .eraseToAnyPublisher()
            }
        )
    }

    /// Creates a Feedback which re-evaluates the given effect every time an
    /// event fires.
    ///
    /// If the previous effect is still alive when a new one is about to start,
    /// the previous one would automatically be cancelled.
    ///
    /// - parameters:
    ///   - transform: The transform to apply on the event.
    ///   - effects: The side effect accepting transformed values produced by
    ///              `transform` and yielding events that eventually affect
    ///              the state.
    public static func event<Payload>(
        _ transform: @escaping (Event) -> Payload?,
        effect: @escaping (Payload, State, Dependencies) -> Effect
    ) -> Feedback {
        custom { input, output, dependencies in
            // NOTE: `observe(on:)` should be applied on the inner producers, so
            //       that cancellation due to state changes would be able to
            //       cancel outstanding events that have already been scheduled.
            input
                .compactMap { state, event -> (State, Payload)? in
                    guard let payload = event.flatMap(transform) else { return nil }
                    return (state, payload)
                }
                .flatMapLatest { state, payload in
                    effect(payload, state, dependencies).publisher
                }
                .enqueue(to: output)
        }
    }

    private static func firstValueAfterNil<Value, EventsPublisher: Publisher>(
        _ transform: @escaping (State) -> Value?,
        events: @escaping (Value, Dependencies) -> EventsPublisher
    ) -> Feedback where EventsPublisher.Output == Event, EventsPublisher.Failure == Never {
        .compacting(
            input: { input -> AnyPublisher<NilEdgeTransition<Value>, Never> in
                input
                    .map { $0.0 }
                    .scan((lastWasNil: true, output: NilEdgeTransition<Value>?.none)) { acum, state in
                        var temp = acum
                        let result = transform(state)
                        temp.output = NilEdgeTransition<Value>?.none

                        switch (temp.lastWasNil, result) {
                        case (true, .none), (false, .some):
                            return temp
                        case let (true, .some(value)):
                            temp.lastWasNil = false
                            temp.output = NilEdgeTransition<Value>.populated(value)
                        case (false, .none):
                            temp.lastWasNil = true
                            temp.output = NilEdgeTransition<Value>.cleared
                        }
                        return temp
                    }
                    .compactMap { $0.output }
                    .eraseToAnyPublisher()
            },
            events: { transition, dependencies -> AnyPublisher<EventsPublisher.Output, EventsPublisher.Failure> in
                switch transition {
                case let .populated(value):
                    return events(value, dependencies).eraseToAnyPublisher()
                case .cleared:
                    return Empty().eraseToAnyPublisher()
                }
            }
        )
    }

    public static func state<Value>(
        firstAfterNil transform: @escaping (State) -> Value?,
        effect: @escaping (Value, Dependencies) -> Effect
    ) -> Feedback {
        firstValueAfterNil(transform) { value, dependencies in
            effect(value, dependencies)
                .publisher
                .eraseToAnyPublisher()
        }
    }
}

extension Feedback {
    /// Transforms a Feedback that works on local state, event, and dependencies into one that works on
    /// global state, event and dependencies. It accomplishes this by providing 3 transformations to
    /// the method:
    ///
    ///   * A key path that can get a piece of local state from the global state.
    ///   * A case path that can extract/embed a local event into a global event.
    ///   * A function that can transform the global dependencies into local dependencies.
    public func pullback<GlobalState, GlobalEvent, GlobalDependencies>(
        state stateKeyPath: KeyPath<GlobalState, State>,
        event eventCasePath: CasePath<GlobalEvent, Event>,
        dependencies toLocal: @escaping (GlobalDependencies) -> Dependencies
    ) -> Feedback<GlobalState, GlobalEvent, GlobalDependencies> {
        .init { input, output, dependencies in
            let scoped = input
                .map { state, event in
                    (state[keyPath: stateKeyPath], event.flatMap(eventCasePath.extract(from:)))
                }
                .eraseToAnyPublisher()
            return self.events(
                scoped,
                output.pullback(eventCasePath.embed),
                toLocal(dependencies)
            )
        }
    }

    /// Transforms a Feedback that works on local state, event, and dependencies into one that works on
    /// global state, event and dependencies. It accomplishes this by providing 3 transformations to
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
    ///   * A function that can transform the global dependencies into local dependencies.
    public func pullback<GlobalState, GlobalEvent, GlobalDependencies>(
        state stateCasePath: CasePath<GlobalState, State>,
        event eventCasePath: CasePath<GlobalEvent, Event>,
        dependencies toLocal: @escaping (GlobalDependencies) -> Dependencies
    ) -> Feedback<GlobalState, GlobalEvent, GlobalDependencies> {
        .init { input, output, dependencies in
            let scoped: AnyPublisher<(State, Event?), Never> = input
                .compactMap { (stateAndEvent: (GlobalState, GlobalEvent?)) -> (State, Event?)? in
                    guard let localState = stateCasePath.extract(from: stateAndEvent.0) else { return nil }
                    return (localState, stateAndEvent.1.flatMap(eventCasePath.extract(from:)))
                }
                .eraseToAnyPublisher()

            return self.events(
                scoped,
                output.pullback(eventCasePath.embed),
                toLocal(dependencies)
            )
        }
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
