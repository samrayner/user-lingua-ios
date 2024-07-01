// IfLetStore.swift

import SwiftUI

public struct IfLetStore<State, Event, Content: View>: View {
    private let store: Store<State?, Event>
    private let content: (ViewStore<State?, Event>) -> Content

    public init<IfContent: View, ElseContent: View>(
        store: Store<State?, Event>,
        @ViewBuilder then ifContent: @escaping (Store<State, Event>) -> IfContent,
        @ViewBuilder else elseContent: @escaping () -> ElseContent
    ) where Content == _ConditionalContent<IfContent, ElseContent> {
        self.store = store
        self.content = { viewStore in
            if let state = viewStore[dynamicMember: \State.self] {
                ViewBuilder.buildEither(
                    first: ifContent(
                        store.scoped(to: { $0 ?? state })
                    )
                )
            } else {
                ViewBuilder.buildEither(second: elseContent())
            }
        }
    }

    public init<IfContent: View>(
        store: Store<State?, Event>,
        @ViewBuilder then ifContent: @escaping (Store<State, Event>) -> IfContent
    ) where Content == _ConditionalContent<IfContent, EmptyView> {
        self.init(store: store, then: ifContent, else: EmptyView.init)
    }

    public var body: some View {
        WithViewStore(
            store,
            removingDuplicates: { ($0 != nil) == ($1 != nil) },
            content: content
        )
    }
}
