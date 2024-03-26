// SelectionFeature.swift

import ComposableArchitecture
import Core
import Foundation
import RecognitionFeature
import SFSafeSymbols
import SwiftUI

@Reducer
package struct SelectionFeature {
    @Dependency(NotificationManagerDependency.self) var notificationManager

    package init() {}

    @ObservableState
    package struct State: Equatable {
        package var recognition = RecognitionFeature.State()
        var recognizedStrings: [RecognizedString]?

        package init() {}
    }

    package enum Action {
        case onAppear
        case observeDeviceRotation
        case deviceOrientationDidChange
        case delegate(Delegate)
        case recognition(RecognitionFeature.Action)

        @CasePathable
        package enum Delegate {
            case didDismiss
            case didSelectString(RecordedString)
        }
    }

    package var body: some ReducerOf<Self> {
        Scope(state: \.recognition, action: \.recognition) {
            RecognitionFeature()
        }

        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    await send(.recognition(.start))
                }
            case .observeDeviceRotation:
                return .run { send in
                    for await _ in await notificationManager.observe(UIDevice.orientationDidChangeNotification) {
                        await send(.deviceOrientationDidChange)
                    }
                }
            case .deviceOrientationDidChange:
                state.recognizedStrings = nil
                return .run { send in
                    await send(.recognition(.start))
                }
            case let .recognition(.delegate(.didRecognizeStrings(recognizedStrings))):
                state.recognizedStrings = recognizedStrings
                return .none
            case .recognition, .delegate:
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
                RecognitionFeatureView(store: store.scope(state: \.recognition, action: \.recognition))

                if let recognizedStrings = store.recognizedStrings {
                    HighlightsView(
                        recognizedStrings: recognizedStrings,
                        onSelectString: { store.send(.delegate(.didSelectString($0))) }
                    )
                    .ignoresSafeArea()

                    Button(action: { store.send(.delegate(.didDismiss)) }) {
                        Image(systemSymbol: .xmarkCircleFill)
                            .padding()
                    }
                }

                if store.recognition.isRecognizingStrings {
                    ProgressView()
                }
            }
            .onAppear { store.send(.onAppear) }
            .task { await store.send(.observeDeviceRotation).finish() }
        }
    }
}
