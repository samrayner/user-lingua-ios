// Feature.swift

public protocol Feature<State, Event, Dependencies> {
    associatedtype State
    associatedtype Event
    associatedtype Dependencies
    static func reducer() -> ReducerOf<Self>
    static var feedback: FeedbackOf<Self> { get }
}

extension Feature {
    public static func store(
        initialState: State,
        dependencies: Dependencies
    ) -> Store<State, Event> {
        StoreOf<Self>(
            initialState: initialState,
            feedbacks: [feedback],
            reducer: reducer(),
            dependencies: dependencies
        )
    }
}
