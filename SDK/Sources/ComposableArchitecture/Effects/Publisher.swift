// Publisher.swift

import Combine

extension Effect {
    /// Creates an effect from a Combine publisher.
    ///
    /// - Parameter createPublisher: The closure to execute when the effect is performed.
    /// - Returns: An effect wrapping a Combine publisher.
    public static func publisher<P: Publisher>(_ createPublisher: () -> P) -> Self
        where P.Output == Action, P.Failure == Never {
        Self(
            operation: .publisher(
                createPublisher().eraseToAnyPublisher()
            )
        )
    }
}

public struct _EffectPublisher<Action>: Publisher {
    public typealias Output = Action
    public typealias Failure = Never

    let effect: Effect<Action>

    public init(_ effect: Effect<Action>) {
        self.effect = effect
    }

    public func receive<S: Combine.Subscriber>(
        subscriber: S
    ) where S.Input == Action, S.Failure == Failure {
        publisher.subscribe(subscriber)
    }

    private var publisher: AnyPublisher<Action, Failure> {
        switch effect.operation {
        case .none:
            Empty().eraseToAnyPublisher()
        case let .publisher(publisher):
            publisher
        case let .run(priority, operation):
            .create { subscriber in
                let task = Task(priority: priority) { @MainActor in
                    defer { subscriber.send(completion: .finished) }
                    await operation(Send { subscriber.send($0) })
                }
                return AnyCancellable {
                    task.cancel()
                }
            }
        }
    }
}
