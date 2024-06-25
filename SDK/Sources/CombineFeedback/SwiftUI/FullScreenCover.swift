// FullScreenCover.swift

import SwiftUI

extension View {
    public func fullScreenCover<State, Event, ScopedState, ScopedEvent>(
        store: Store<State, Event>,
        get getState: @escaping (State) -> ScopedState?,
        set setState: @escaping (ScopedState?) -> Event,
        event: @escaping (ScopedEvent) -> Event,
        onDismiss: Event? = nil,
        @ViewBuilder content: @escaping (Store<ScopedState, ScopedEvent>) -> some View
    ) -> some View {
        fullScreenCover(
            isPresented: Binding(
                get: { getState(store.state) != nil },
                set: {
                    if !$0 { store.send(setState(nil)) }
                }
            ),
            onDismiss: { onDismiss.map(store.send) }
        ) {
            if let store = store.scoped(to: getState, event: event) {
                content(store)
            }
        }
    }
}
