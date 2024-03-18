// SelectionFeature.swift

import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
struct SelectionFeature {
    @Dependency(StringRecognizerDependency.self) var stringRecognizer
    @Dependency(WindowManagerDependency.self) var windowManager
    @Dependency(UserLinguaObservableDependency.self) var appViewModel

    @ObservableState
    struct State: Equatable {
        @ObservableState
        enum Stage: Equatable {
            case preparingFacade
            case takingScreenshot
            case recognizingStrings
            case presentingStrings([RecognizedString])

            var isLoading: Bool {
                switch self {
                case .preparingFacade, .takingScreenshot, .recognizingStrings:
                    true
                case .presentingStrings:
                    false
                }
            }
        }

        var facade: UIImage?

        var stage: Stage = .preparingFacade
    }

    enum Action {
        case onAppear
        case recognizeStrings
        case presentStrings([RecognizedString])
        case delegate(Delegate)

        @CasePathable
        enum Delegate {
            case didDismiss
            case didSelectString(RecordedString)
        }
    }

    var body: some ReducerOf<Self> {
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

struct SelectionFeatureView: View {
    let store: StoreOf<SelectionFeature>

    var body: some View {
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
