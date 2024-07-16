// Publisher+Extras.swift

import Combine
import Foundation

extension Publisher {
    public func mapToResult() -> AnyPublisher<Result<Output, Failure>, Never> {
        map(Result.success)
            .catch { error in
                Just(Result.failure(error))
            }
            .eraseToAnyPublisher()
    }

    /// Includes the current element as well as the previous element from the upstream publisher in a tuple where the previous element is
    /// optional.
    /// The first time the upstream publisher emits an element, the previous element will be `nil`.
    ///
    ///     let range = (1...5)
    ///     cancellable = range.publisher
    ///         .withPrevious()
    ///         .sink { print ("(\($0.previous), \($0.current))", terminator: " ") }
    ///      // Prints: "(nil, 1) (Optional(1), 2) (Optional(2), 3) (Optional(3), 4) (Optional(4), 5) ".
    ///
    /// - Returns: A publisher of a tuple of the previous and current elements from the upstream publisher.
    public func withPrevious() -> AnyPublisher<(previous: Output?, current: Output), Failure> {
        scan((Output?, Output)?.none) { ($0?.1, $1) }
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    public func onlyWithPrevious() -> AnyPublisher<(previous: Output, current: Output), Failure> {
        withPrevious()
            .compactMap { change -> (Output, Output)? in
                guard let previous = change.previous else { return nil }
                return (previous, change.current)
            }
            .eraseToAnyPublisher()
    }

    public func append(_ element: @escaping (Output?) -> Output?) -> AnyPublisher<Output, Failure> {
        map(Emission.emitted)
            .append(.appended)
            .withPrevious()
            .compactMap { previous, current -> Output? in
                switch (previous, current) {
                case let (_, .emitted(value)):
                    value
                case let (.emitted(lastValue), .appended):
                    element(lastValue)
                case (nil, .appended):
                    element(nil)
                case (.appended, .appended):
                    nil
                }
            }
            .eraseToAnyPublisher()
    }

    public func mapToEvents<Event>(
        output transformValue: @escaping (Output) -> Event,
        finished transformFinished: @escaping (Output?) -> Event?
    ) -> AnyPublisher<Event, Never> where Failure == Never {
        map { ($0, transformValue($0)) }
            .append { lastValuePair in
                transformFinished(lastValuePair?.0)
                    .map { (lastValuePair?.0, $0) }
            }
            .map(\.1)
            .eraseToAnyPublisher()
    }

    public func mapToEvents<Event>(
        output transformValue: @escaping (Output) -> Event,
        failure transformFailure: @escaping (Failure) -> Event,
        finished transformFinished: @escaping (Output?) -> Event? = { _ in nil }
    ) -> AnyPublisher<Event, Never> {
        map { ($0, transformValue($0)) }
            .append { lastValuePair in
                transformFinished(lastValuePair?.0)
                    .map { (lastValuePair?.0, $0) }
            }
            .map(\.1)
            .catch { Just(transformFailure($0)) }
            .eraseToAnyPublisher()
    }
}

private enum Emission<Value> {
    case emitted(Value)
    case appended
}
