// SelectionFeature.swift

import ComposableArchitecture
import Core
import Foundation
import SFSafeSymbols
import SwiftUI

@Reducer
package struct SelectionFeature {
    @Dependency(StringRecognizerDependency.self) var stringRecognizer

    package init() {}

    @ObservableState
    package struct State: Equatable {
        var recognizedStrings: [RecognizedString]?

        package var isRecognizingStrings: Bool {
            recognizedStrings == nil
        }

        package init() {}
    }

    package enum Action {
        case onAppear
        case presentStrings([RecognizedString])
        case delegate(Delegate)

        @CasePathable
        package enum Delegate {
            case didDismiss
            case didSelectString(RecordedString)
        }
    }

    package var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    try await send(.presentStrings(stringRecognizer.recognizeStrings()))
                }
            case let .presentStrings(strings):
                state.recognizedStrings = strings
                return .none
            case .delegate:
                return .none
            }
        }
    }
}

package struct SelectionFeatureView: View {
    package let store: StoreOf<SelectionFeature>

    package init(store: StoreOf<SelectionFeature>) {
        self.store = store
    }

    package var body: some View {
        WithPerceptionTracking {
            ZStack(alignment: .topLeading) {
                Group {
                    if let recognizedStrings = store.recognizedStrings {
                        HighlightsView(
                            recognizedStrings: recognizedStrings,
                            onSelectString: { store.send(.delegate(.didSelectString($0))) }
                        )
                    }

                    if store.isRecognizingStrings {
                        ProgressView()
                    }
                }
                .ignoresSafeArea()

                if !store.isRecognizingStrings {
                    Button(action: { store.send(.delegate(.didDismiss)) }) {
                        Image(systemSymbol: .xmarkCircleFill)
                            .padding()
                    }
                }
            }
            .onAppear { store.send(.onAppear) }
        }
    }
}
