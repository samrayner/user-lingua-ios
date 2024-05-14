// RecognitionFeature.swift

import Core
import Foundation
import Lib_ComposableArchitecture
import SwiftUI
import UIKit

@Reducer
package struct RecognitionFeature {
    @Dependency(StringRecognizerDependency.self) var stringRecognizer
    @Dependency(WindowServiceDependency.self) var windowService
    @Dependency(UserLinguaObservableDependency.self) var appViewModel

    package init() {}

    @ObservableState
    package struct State: Equatable {
        package var isRecognizingStrings = false
        package var isTakingScreenshot = false
        var appFacade: UIImage?
        var appYOffset: CGFloat = 0

        package init() {}
    }

    package enum Action {
        case start
        case prepareApp
        case recognizeStrings
        case resetApp
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
                    await send(.prepareApp)
                }
            case .prepareApp:
                state.appFacade = windowService.screenshotAppWindow()
                state.isTakingScreenshot = true
                state.appYOffset = windowService.appYOffset
                windowService.resetAppPosition()
                appViewModel.refresh() // refresh app views with scrambled text
                return .run { send in
                    await send(.recognizeStrings)
                }
            case .recognizeStrings:
                guard let screenshot = windowService.screenshotAppWindow() else {
                    return .run { send in
                        await send(.resetApp)
                        await send(.delegate(.didRecognizeStrings([])))
                    }
                }

                return .run { send in
                    await send(.resetApp)
                    let recognizedStrings = try await stringRecognizer.recognizeStrings(in: screenshot)
                    await send(.delegate(.didRecognizeStrings(recognizedStrings)))
                }
            case .resetApp:
                windowService.positionApp(yOffset: state.appYOffset, animationDuration: 0)
                state.isTakingScreenshot = false
                appViewModel.refresh() // refresh app views with unscrambled text
                return .run { send in
                    await send(.finish)
                }
            case .finish:
                state = .init()
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
