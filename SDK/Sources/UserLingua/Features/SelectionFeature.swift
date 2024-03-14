// SelectionFeature.swift

import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
struct SelectionFeature {
    @Dependency(StringRecognizerDependency.self) var stringRecognizer

    @ObservableState
    struct State: Equatable {
        enum Stage: Equatable {
            case takingScreenshot
            case recognizingStrings
            case presentingStrings([RecognizedString])
        }

        var stage: Stage = .takingScreenshot
    }

    enum Action {
        case onAppear
        case didRecognizeStrings([RecognizedString])
        case delegate(Delegate)

        @CasePathable
        enum Delegate {
            case didHide
            case didSelectString(RecordedString)
        }
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // TODO: ScreenshotProvider dependency
                guard let screenshot = UserLingua.shared.screenshotApp() else {
                    state.stage = State.Stage.presentingStrings([])
                    return .none
                }

                state.stage = .recognizingStrings

                return .run { send in
                    let recognizedStrings = try await stringRecognizer.recognizeStrings(in: screenshot)
                    await send(.didRecognizeStrings(recognizedStrings))
                }
            case let .didRecognizeStrings(strings):
                state.stage = .presentingStrings(strings)
                return .none
            case .delegate:
                return .none
            }
        }
    }
}

struct SelectionFeatureView: View {
    @Perception.Bindable var store: StoreOf<SelectionFeature>

    var body: some View {
        WithPerceptionTracking {
            switch store.state.stage {
            case .takingScreenshot:
                EmptyView()
            case .recognizingStrings:
                ProgressView()
            case let .presentingStrings(recognizedStrings):
                HighlightsView(
                    recognizedStrings: recognizedStrings,
                    onSelectString: { store.send(.delegate(.didSelectString($0))) }
                )
            }
        }
    }
}
