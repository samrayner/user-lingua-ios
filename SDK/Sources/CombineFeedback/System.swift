// System.swift

import Combine
import Foundation

extension Publishers {
    public static func system<State, Event, Dependencies>(
        initial: State,
        feedbacks: [Feedback<State, Event, Dependencies>],
        reduce: Reducer<State, Event>,
        dependencies: Dependencies
    ) -> AnyPublisher<State, Never> {
        Publishers.FeedbackLoop(
            initial: initial,
            reduce: reduce,
            feedbacks: feedbacks,
            dependencies: dependencies
        )
        .eraseToAnyPublisher()
    }
}

extension Publisher where Output == Never, Failure == Never {
    public func start() -> Cancellable {
        sink(receiveValue: { _ in })
    }
}
