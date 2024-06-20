// FeedbackEventConsumer.swift

import Foundation

struct Token: Equatable {
    let value: UUID

    init() {
        self.value = UUID()
    }
}

public class FeedbackEventConsumer<Event> {
    func process(_: Event, for _: Token) {
        fatalError("This is an abstract class. You must subclass this and provide your own implementation")
    }

    func dequeueAllEvents(for _: Token) {
        fatalError("This is an abstract class. You must subclass this and provide your own implementation")
    }
}

extension FeedbackEventConsumer {
    func pullback<LocalEvent>(_ pull: @escaping (LocalEvent) -> Event) -> FeedbackEventConsumer<LocalEvent> {
        PullBackConsumer(upstream: self, pull: pull)
    }
}

final class PullBackConsumer<LocalEvent, Event>: FeedbackEventConsumer<LocalEvent> {
    private let upstream: FeedbackEventConsumer<Event>
    private let pull: (LocalEvent) -> Event

    init(upstream: FeedbackEventConsumer<Event>, pull: @escaping (LocalEvent) -> Event) {
        self.pull = pull
        self.upstream = upstream
        super.init()
    }

    override func process(_ event: LocalEvent, for token: Token) {
        upstream.process(pull(event), for: token)
    }

    override func dequeueAllEvents(for token: Token) {
        upstream.dequeueAllEvents(for: token)
    }
}
