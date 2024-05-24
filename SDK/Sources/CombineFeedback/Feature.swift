// Feature.swift

public protocol Feature<State, Event, Dependencies> {
    associatedtype State
    associatedtype Event
    associatedtype Dependencies
    static func reducer() -> ReducerOf<Self>
    static func feedback() -> FeedbackOf<Self>
}
