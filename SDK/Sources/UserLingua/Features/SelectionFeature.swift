// SelectionFeature.swift

import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
struct SelectionFeature {
    @Dependency(StringRecognizerDependency.self) var stringRecognizer
    @Dependency(WindowManagerDependency.self) var windowManager
    @Dependency(UserLinguaObservableDependency.self) var userLinguaViewModel
    @Dependency(\.continuousClock) var clock

    @ObservableState
    struct State: Equatable {
        enum Stage: Equatable {
            case preparingForRecognition
            case obscuringApp(with: UIImage)
            case recognizingStrings
            case presentingStrings([RecognizedString])
        }

        var stage: Stage = .preparingForRecognition

        var isCapturingAppWindow: Bool {
            switch stage {
            case .preparingForRecognition, .obscuringApp:
                true
            default:
                false
            }
        }
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
                guard let screenshot = windowManager.screenshotAppWindow() else {
                    state.stage = .presentingStrings([])
                    return .none
                }

                state.stage = .obscuringApp(with: screenshot)

                userLinguaViewModel.refresh() // refresh views with scrambled text

                return .run { send in
                    try await clock.sleep(for: .seconds(0.1)) // allow for views to refresh
                    await send(.recognizeStrings)
                }
            case .recognizeStrings:
                guard let screenshot = windowManager.screenshotAppWindow() else {
                    state.stage = .presentingStrings([])
                    return .none
                }

                state.stage = .recognizingStrings

                userLinguaViewModel.refresh() // refresh views with unscrambled text

                return .run { send in
                    let recognizedStrings = try await stringRecognizer.recognizeStrings(in: screenshot)
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
    @Perception.Bindable var store: StoreOf<SelectionFeature>

    var body: some View {
        WithPerceptionTracking {
            switch store.state.stage {
            case .preparingForRecognition:
                EmptyView()
            case let .obscuringApp(with: image):
                Image(uiImage: image)
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
