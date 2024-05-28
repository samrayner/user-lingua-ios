// FeedbackLoop.swift

import Combine

extension Publishers {
    public struct FeedbackLoop<Output, Event, Dependencies>: Publisher {
        public typealias Failure = Never
        let initial: Output
        let reduce: Reducer<Output, Event>
        let feedbacks: [Feedback<Output, Event, Dependencies>]
        let dependencies: Dependencies

        public init(
            initial: Output,
            reduce: Reducer<Output, Event>,
            feedbacks: [Feedback<Output, Event, Dependencies>],
            dependencies: Dependencies
        ) {
            self.initial = initial
            self.reduce = reduce
            self.feedbacks = feedbacks
            self.dependencies = dependencies
        }

        public func receive<S>(subscriber: S) where S: Combine.Subscriber, Failure == S.Failure, Output == S.Input {
            let floodgate = Floodgate<Output, Event, S, Dependencies>(
                state: initial,
                feedbacks: feedbacks,
                sink: subscriber,
                reducer: reduce,
                dependencies: dependencies
            )
            subscriber.receive(subscription: floodgate)
            floodgate.bootstrap()
        }
    }
}
