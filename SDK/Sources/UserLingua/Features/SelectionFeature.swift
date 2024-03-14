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
            case preparingForScreenshot
            case takingScreenshot
            case recognizingStrings
            case presentingStrings([RecognizedString])
        }

        var stage: Stage = .preparingForScreenshot

        var isDetectingStrings: Bool {
            [.preparingForScreenshot, .takingScreenshot].contains(stage)
        }
    }

    enum Action {
        case onAppear
        case didPrepareForScreenshot
        case didRecognizeStrings([RecognizedString])
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
                return .run { send in
                    UserLingua.shared.reloadViews()
                    try await Task.sleep(for: .seconds(0.1))
                    await send(.didPrepareForScreenshot)
                }
            case .didPrepareForScreenshot:
                state.stage = .takingScreenshot

                // TODO: ScreenshotProvider dependency
                guard let screenshot = UserLingua.shared.screenshotApp() else {
                    state.stage = .presentingStrings([])
                    return .none
                }

                state.stage = .recognizingStrings

                UserLingua.shared.reloadViews()

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
            case .preparingForScreenshot, .takingScreenshot:
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
        .onAppear { store.send(.onAppear) }
    }
}
