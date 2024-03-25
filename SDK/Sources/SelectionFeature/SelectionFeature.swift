// SelectionFeature.swift

import ComposableArchitecture
import Core
import Foundation
import SFSafeSymbols
import SwiftUI

@Reducer
package struct SelectionFeature {
    @Dependency(StringRecognizerDependency.self) var stringRecognizer
    @Dependency(WindowManagerDependency.self) var windowManager
    @Dependency(UserLinguaObservableDependency.self) var appViewModel

    package init() {}

    @ObservableState
    package struct State: Equatable {
        package var recognizedStrings: [RecognizedString]?

        package init() {}

        var isRecognizingStrings: Bool {
            recognizedStrings == nil
        }
    }

    package enum Action {
        case onAppear
        case recognizeStrings
        case presentStrings([RecognizedString])
        case delegate(Delegate)

        @CasePathable
        package enum Delegate {
            case didDismiss
            case willTakeScreenshot
            case didTakeScreenshot
            case didSelectString(RecordedString)
        }
    }

    package var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    await send(.delegate(.willTakeScreenshot))
                    await send(.recognizeStrings)
                }
            case .recognizeStrings:
                guard let screenshot = windowManager.screenshotAppWindow() else {
                    state.recognizedStrings = []
                    return .none
                }

                return .run { send in
                    await send(.delegate(.didTakeScreenshot))
                    let recognizedStrings = try await stringRecognizer.recognizeStrings(in: screenshot)
                    await send(.presentStrings(recognizedStrings))
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
