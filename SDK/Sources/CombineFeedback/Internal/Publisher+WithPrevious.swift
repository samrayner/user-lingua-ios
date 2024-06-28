// Publisher+WithPrevious.swift

import Combine

extension Publisher {
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
    func withPrevious() -> AnyPublisher<(previous: Output?, current: Output), Failure> {
        scan((Output?, Output)?.none) { ($0?.1, $1) }
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    func onlyWithPrevious() -> AnyPublisher<(previous: Output, current: Output), Failure> {
        withPrevious()
            .compactMap { change -> (Output, Output)? in
                guard let previous = change.previous else { return nil }
                return (previous, change.current)
            }
            .eraseToAnyPublisher()
    }
}
