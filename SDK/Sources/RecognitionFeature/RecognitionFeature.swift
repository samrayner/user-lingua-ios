// RecognitionFeature.swift

import ComposableArchitecture
import Core
import Foundation
import SwiftUI
import UIKit

@Reducer
package struct RecognitionFeature {
    @Dependency(StringRecognizerDependency.self) var stringRecognizer
    @Dependency(WindowManagerDependency.self) var windowManager
    @Dependency(UserLinguaObservableDependency.self) var appViewModel

    package init() {}

    @ObservableState
    package struct State: Equatable {
        package var isRecognizingStrings = false
        package var isTakingScreenshot = false
        var appFacade: UIImage?

        package init() {}
    }

    package enum Action {
        case start
        case setUpScreenshot
        case recognizeStrings
        case tearDownScreenshot
        case finish
        case delegate(Delegate)

        @CasePathable
        package enum Delegate {
            case didRecognizeStrings([RecognizedString])
        }
    }

    package var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .start:
                state.isRecognizingStrings = true
                return .run { send in
                    await send(.setUpScreenshot)
                }
            case .setUpScreenshot:
                state.appFacade = windowManager.screenshotAppWindow()
                state.isTakingScreenshot = true
                appViewModel.refresh() // refresh app views with scrambled text
                return .run { send in
                    await send(.recognizeStrings)
                }
            case .recognizeStrings:
                guard let screenshot = windowManager.screenshotAppWindow() else {
                    return .run { send in
                        await send(.tearDownScreenshot)
                        await send(.delegate(.didRecognizeStrings([])))
                    }
                }

                return .run { send in
                    await send(.tearDownScreenshot)
                    let recognizedStrings = try await stringRecognizer.recognizeStrings(in: screenshot)
                    await send(.delegate(.didRecognizeStrings(recognizedStrings)))
                }
            case .tearDownScreenshot:
                state.isTakingScreenshot = false
                appViewModel.refresh() // refresh app views with unscrambled text
                return .run { send in
                    await send(.finish)
                }
            case .finish:
                state.appFacade = nil
                state.isRecognizingStrings = false
                return .none
            case .delegate:
                return .none
            }
        }
    }
}

package struct RecognitionFeatureView: View {
    package let store: StoreOf<RecognitionFeature>

    package init(store: StoreOf<RecognitionFeature>) {
        self.store = store
    }

    package var body: some View {
        WithPerceptionTracking {
            if let appFacade = store.appFacade {
                Image(uiImage: appFacade)
                    .ignoresSafeArea()
            }
        }
    }
}
