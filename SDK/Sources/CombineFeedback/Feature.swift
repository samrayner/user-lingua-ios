public protocol Feature {
    associatedtype State
    associatedtype Event
    static func reducer() -> Reducer<State, Event>
}
