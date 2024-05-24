// Feedback.swift

import CasePaths
import Combine

public struct Feedback<State, Event, Dependency> {
    public enum Action {
        case observe(AnyPublisher<Event, Never>)
        case run(((Event) -> Void) -> Void)
        case none

        var publisher: AnyPublisher<Event, Never> {
            switch self {
            case let .observe(publisher):
                return publisher
            case let .run(closure):
                let subject = PassthroughSubject<Event, Never>()
                closure(subject.send)
                return subject.eraseToAnyPublisher()
            case .none:
                return Empty().eraseToAnyPublisher()
            }
        }
    }

    public let events: (
        _ state: AnyPublisher<(State, Event?), Never>,
        _ output: FeedbackEventConsumer<Event>,
        _ dependency: Dependency
    ) -> Cancellable

    init(events: @escaping (
        _ state: AnyPublisher<(State, Event?), Never>,
        _ output: FeedbackEventConsumer<Event>,
        _ dependency: Dependency
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
            _ dependency: Dependency
        ) -> P
    ) -> Feedback where P.Failure == Never, P.Output == Never {
        Feedback { state, output, dependency -> Cancellable in
            setup(state, output, dependency).start()
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
    private static func compacting<U, Effect: Publisher>(
        state transform: @escaping (AnyPublisher<State, Never>) -> AnyPublisher<U, Never>,
        effects: @escaping (U, Dependency) -> Effect
    ) -> Feedback where Effect.Output == Event, Effect.Failure == Never {
        custom { state, output, dependency in
            // NOTE: `observe(on:)` should be applied on the inner producers, so
            //       that cancellation due to state changes would be able to
            //       cancel outstanding events that have already been scheduled.
            transform(state.map(\.0).eraseToAnyPublisher())
                .flatMapLatest { effects($0, dependency).enqueue(to: output) }
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
    public static func state<Control: Equatable>(
        scope: @escaping (State) -> Control? = { state -> State in state },
        removeDuplicates: Bool = false,
        action: @escaping (Control, Dependency) -> Action
    ) -> Feedback where State: Equatable {
        compacting(state: {
            if removeDuplicates {
                $0.map(scope).removeDuplicates().eraseToAnyPublisher()
            } else {
                $0.map(scope).eraseToAnyPublisher()
            }
        }, effects: { control, dependency -> AnyPublisher<Event, Never> in
            guard let control else { return Empty().eraseToAnyPublisher() }

            return action(control, dependency)
                .publisher
                .eraseToAnyPublisher()
        })
    }

    public static func state<Control: Equatable>(
        _ scope: @escaping (State) -> Control = { state -> State in state },
        removeDuplicates: Bool = false,
        action: @escaping (Control, Dependency) -> Action
    ) -> Feedback where State: Equatable {
        state(
            scope: { Optional(scope($0)) },
            removeDuplicates: removeDuplicates,
            action: action
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
        action: @escaping (State, Dependency) -> Action
    ) -> Feedback {
        firstValueAfterNil(
            { state -> State? in
                predicate(state) ? state : nil
            },
            effects: { state, dependency -> AnyPublisher<Event, Never> in
                action(state, dependency)
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
        action: @escaping (Payload, State, Dependency) -> Action
    ) -> Feedback {
        custom { input, output, dependency in
            // NOTE: `observe(on:)` should be applied on the inner producers, so
            //       that cancellation due to state changes would be able to
            //       cancel outstanding events that have already been scheduled.
            input
                .compactMap { state, event -> (State, Payload)? in
                    guard let payload = event.flatMap(transform) else { return nil }
                    return (state, payload)
                }
                .flatMapLatest { state, payload in
                    action(payload, state, dependency).publisher
                }
                .enqueue(to: output)
        }
    }

    private static func firstValueAfterNil<Value, Effect: Publisher>(
        _ transform: @escaping (State) -> Value?,
        effects: @escaping (Value, Dependency) -> Effect
    ) -> Feedback where Effect.Output == Event, Effect.Failure == Never {
        return .compacting(
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
            effects: { transition, dependency -> AnyPublisher<Effect.Output, Effect.Failure> in
                switch transition {
                case let .populated(value):
                    return effects(value, dependency).eraseToAnyPublisher()
                case .cleared:
                    return Empty().eraseToAnyPublisher()
                }
            }
        )
    }

    public static func state<Value>(
        firstAfterNil transform: @escaping (State) -> Value?,
        action: @escaping (Value, Dependency) -> Action
    ) -> Feedback {
        firstValueAfterNil(transform) { value, dependency in
            action(value, dependency)
                .publisher
                .eraseToAnyPublisher()
        }
    }
}

extension Feedback {
    /// Transforms a Feedback that works on local state, event, and dependency into one that works on
    /// global state, action and dependency. It accomplishes this by providing 3 transformations to
    /// the method:
    ///
    ///   * A key path that can get a piece of local state from the global state.
    ///   * A case path that can extract/embed a local event into a global event.
    ///   * A function that can transform the global dependency into a local dependency.
    public func pullback<GlobalState, GlobalEvent, GlobalDependency>(
        state stateKeyPath: KeyPath<GlobalState, State>,
        event eventCasePath: CasePath<GlobalEvent, Event>,
        dependency toLocal: @escaping (GlobalDependency) -> Dependency
    ) -> Feedback<GlobalState, GlobalEvent, GlobalDependency> {
        return Feedback<GlobalState, GlobalEvent, GlobalDependency>(events: { state, consumer, dependency in
            let state = state.map {
                ($0[keyPath: stateKeyPath], $1.flatMap(eventCasePath.extract(from:)))
            }.eraseToAnyPublisher()
            return self.events(
                state,
                consumer.pullback(eventCasePath.embed),
                toLocal(dependency)
            )
        })
    }

    /// Transforms a Feedback that works on local state, event, and dependency into one that works on
    /// global state, action and dependency. It accomplishes this by providing 3 transformations to
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
    ///   * A function that can transform the global dependency into a local dependency.
    public func pullback<GlobalState, GlobalEvent, GlobalDependency>(
        state stateCasePath: CasePath<GlobalState, State>,
        event eventCasePath: CasePath<GlobalEvent, Event>,
        dependency toLocal: @escaping (GlobalDependency) -> Dependency
    ) -> Feedback<GlobalState, GlobalEvent, GlobalDependency> {
        return Feedback<GlobalState, GlobalEvent, GlobalDependency>(events: { state, consumer, dependency in
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
                toLocal(dependency)
            )
        })
    }

    public static func combine(
        _ feedbacks: Feedback...
    ) -> Feedback {
        Feedback { state, consumer, dependency -> Cancellable in
            feedbacks.map { feedback -> Cancellable in
                feedback.events(state, consumer, dependency)
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
    public func optional() -> Feedback<State?, Event, Dependency> {
        Feedback<State?, Event, Dependency> { state, output, dependency in
            self.events(
                state.filter { stateAndEvent -> Bool in
                    stateAndEvent.0 != nil
                }
                .map { ($0!, $1) }
                .eraseToAnyPublisher(),
                output,
                dependency
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
