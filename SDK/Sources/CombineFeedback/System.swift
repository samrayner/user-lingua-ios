// System.swift

import Combine
import Foundation

extension Publishers {
    public static func system<State, Event, Dependency>(
        initial: State,
        feedbacks: [Feedback<State, Event, Dependency>],
        reduce: Reducer<State, Event>,
        dependency: Dependency
    ) -> AnyPublisher<State, Never> {
        Publishers.FeedbackLoop(
            initial: initial,
            reduce: reduce,
            feedbacks: feedbacks,
            dependency: dependency
        )
        .eraseToAnyPublisher()
    }
}

extension Publisher where Output == Never, Failure == Never {
    public func start() -> Cancellable {
        sink(receiveValue: { _ in })
    }
}
