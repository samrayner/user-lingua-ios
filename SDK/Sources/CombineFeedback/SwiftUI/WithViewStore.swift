// WithViewStore.swift

import Combine
import SwiftUI

/// A helper view that bridges Store into SwiftUI world by using @ObservedObject ViewStore
/// to listed to the state changes of the Store and render the UI
public struct WithViewStore<State, Event, Content: View>: View {
    @ObservedObject private var viewStore: ViewStore<State, Event>
    private let store: Store<State, Event>
    private let content: (ViewStore<State, Event>) -> Content

    public init(
        _ store: Store<State, Event>,
        removeDuplicates isDuplicate: @escaping (State, State) -> Bool,
        @ViewBuilder content: @escaping (ViewStore<State, Event>) -> Content
    ) {
        self.store = store
        self.content = content
        self.viewStore = store.viewStore(removeDuplicates: isDuplicate)
    }

    public var body: some View {
        content(viewStore)
    }
}

extension WithViewStore where State: Equatable {
    public init(
        _ store: Store<State, Event>,
        @ViewBuilder content: @escaping (ViewStore<State, Event>) -> Content
    ) {
        self.init(store, removeDuplicates: ==, content: content)
    }
}
