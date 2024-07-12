// Feature.swift

public protocol Feature<State, Event, Dependencies> {
    associatedtype State
    associatedtype Event
    associatedtype Dependencies
    static func reducer() -> ReducerOf<Self>
    static var feedbacks: [FeedbackOf<Self>] { get }
}

extension Feature {
    public static var feedback: FeedbackOf<Self> {
        .combine(feedbacks)
    }

    public static func store(
        initialState: State,
        dependencies: Dependencies
    ) -> Store<State, Event> {
        StoreOf<Self>(
            initialState: initialState,
            feedbacks: feedbacks,
            reducer: reducer(),
            dependencies: dependencies
        )
    }
}
