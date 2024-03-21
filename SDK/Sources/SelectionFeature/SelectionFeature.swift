// SelectionFeature.swift

import ComposableArchitecture
import Core
import Foundation
import MemberwiseInit
import SwiftUI

@Reducer
package struct SelectionFeature {
    @Dependency(StringRecognizerDependency.self) var stringRecognizer
    @Dependency(WindowManagerDependency.self) var windowManager
    @Dependency(UserLinguaObservableDependency.self) var appViewModel

    package init() {}

    @ObservableState
    package struct State: Equatable {
        @ObservableState
        package enum Stage: Equatable {
            case preparingFacade
            case takingScreenshot
            case recognizingStrings
            case presentingStrings([RecognizedString])

            package var isLoading: Bool {
                switch self {
                case .preparingFacade, .takingScreenshot, .recognizingStrings:
                    true
                case .presentingStrings:
                    false
                }
            }
        }

        package var facade: UIImage?
        package var stage: Stage = .preparingFacade

        package init() {}
    }

    package enum Action {
        case onAppear
        case recognizeStrings
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
                state.facade = windowManager.screenshotAppWindow()
                state.stage = .takingScreenshot

                appViewModel.refresh() // refresh app views with scrambled text

                return .run { send in
                    // screenshot the scrambled strings on the next run loop to
                    // allow the views to re-render after objectWillChange.send()
                    await send(.recognizeStrings)
                }
            case .recognizeStrings:
                let recognitionScreenshot = windowManager.screenshotAppWindow()

                state.stage = .recognizingStrings

                appViewModel.refresh() // refresh app views with unscrambled text

                return .run { send in
                    var recognizedStrings: [RecognizedString] = []

                    if let recognitionScreenshot {
                        recognizedStrings = try await stringRecognizer.recognizeStrings(in: recognitionScreenshot)
                    }

                    await send(.presentStrings(recognizedStrings))
                }
            case let .presentStrings(strings):
                state.stage = .presentingStrings(strings)
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
            ZStack {
                if case let .presentingStrings(recognizedStrings) = store.stage {
                    HighlightsView(
                        recognizedStrings: recognizedStrings,
                        onSelectString: { store.send(.delegate(.didSelectString($0))) }
                    )
                }

                if store.stage.isLoading {
                    ZStack {
                        if let facade = store.facade {
                            Image(uiImage: facade)
                        }

                        ProgressView()
                    }
                }
            }
            .ignoresSafeArea()
            .onAppear { store.send(.onAppear) }
        }
    }
}
