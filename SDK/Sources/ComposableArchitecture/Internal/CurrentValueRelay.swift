// CurrentValueRelay.swift

import Combine
import Foundation

final class CurrentValueRelay<Output>: Publisher {
    typealias Failure = Never

    private var currentValue: Output
    private var subscriptions: [Subscription<AnySubscriber<Output, Failure>>] = []

    var value: Output {
        get { currentValue }
        set { send(newValue) }
    }

    init(_ value: Output) {
        self.currentValue = value
    }

    func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Never {
        let subscription = Subscription(downstream: AnySubscriber(subscriber))
        subscriptions.append(subscription)
        subscriber.receive(subscription: subscription)
        subscription.forwardValueToBuffer(currentValue)
    }

    func send(_ value: Output) {
        currentValue = value
        for subscription in subscriptions {
            subscription.forwardValueToBuffer(value)
        }
    }
}

extension CurrentValueRelay {
    final class Subscription<Downstream: Subscriber>: Combine.Subscription
        where Downstream.Input == Output, Downstream.Failure == Failure {
        private var demandBuffer: DemandBuffer<Downstream>?

        init(downstream: Downstream) {
            self.demandBuffer = DemandBuffer(subscriber: downstream)
        }

        func forwardValueToBuffer(_ value: Output) {
            _ = demandBuffer?.buffer(value: value)
        }

        func request(_ demand: Subscribers.Demand) {
            _ = demandBuffer?.demand(demand)
        }

        func cancel() {
            demandBuffer = nil
        }
    }
}
