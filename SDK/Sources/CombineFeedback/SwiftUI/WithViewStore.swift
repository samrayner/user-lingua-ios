// WithViewStore.swift

import Combine
import SwiftUI

/// A helper view that bridges Store into SwiftUI world by using @ObservedObject ViewStore
/// to listed to the state changes of the Store and render the UI
public struct WithViewStore<State, ScopedState, Event, Content: View>: View {
    @ObservedObject private var viewStore: ViewStore<ScopedState, Event>
    private let store: Store<State, Event>
    private let content: (ViewStore<ScopedState, Event>) -> Content

    public init(
        _ store: Store<State, Event>,
        removeDuplicates isDuplicate: @escaping (State, State) -> Bool,
        @ViewBuilder content: @escaping (ViewStore<State, Event>) -> Content
    ) where ScopedState == State {
        self.store = store
        self.content = content
        self.viewStore = store.viewStore(removeDuplicates: isDuplicate)
    }

    public init(
        _ store: Store<State, Event>,
        scope: @escaping (State) -> ScopedState,
        @ViewBuilder content: @escaping (ViewStore<ScopedState, Event>) -> Content
    ) where ScopedState: Equatable {
        self.store = store
        self.content = content
        self.viewStore = store.viewStore(scope: scope)
    }

    public var body: some View {
        content(viewStore)
    }
}

extension WithViewStore where State: Equatable {
    public init(
        _ store: Store<State, Event>,
        @ViewBuilder content: @escaping (ViewStore<State, Event>) -> Content
    ) where ScopedState == State {
        self.init(store, removeDuplicates: ==, content: content)
    }
}
