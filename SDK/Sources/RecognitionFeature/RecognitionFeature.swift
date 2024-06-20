// RecognitionFeature.swift

import CasePaths
import Combine
import CombineFeedback
import Core
import Foundation
import SwiftUI
import UIKit

package enum RecognitionFeature: Feature {
    package enum Error: Swift.Error, Equatable {
        case screenshotFailed
        case recognitionFailed(Swift.Error)
    }

    package struct Dependencies {
        let windowService: any WindowServiceProtocol
        let appViewModel: any UserLinguaObservableProtocol
        let stringRecognizer: any StringRecognizerProtocol
    }

    package enum Stage: Equatable {
        case preparingFacade
        case preparingApp
        case recognizingStrings(screenshot: UIImage)
        case resettingApp(yOffset: CGFloat)
    }

    package struct State: Equatable {
        package var stage: Stage?
        var appFacade: UIImage?
        var appYOffset: CGFloat = 0

        package init() {}

        package var isTakingScreenshot: Bool {
            stage == .preparingApp
        }
    }

    package enum Event {
        case start
        case didPrepareFacade(screenshot: UIImage, appYOffset: CGFloat)
        case didPrepareApp(screenshot: UIImage)
        case didFinish(Result<[RecognizedString], Error>)
        case didResetApp
        case delegate(Delegate)

        package enum Delegate {
            case didFinish(Result<[RecognizedString], Error>)
        }
    }

    package static func reducer() -> ReducerOf<Self> {
        .init { state, event in
            switch event {
            case .start:
                state.stage = .preparingFacade
            case let .didPrepareFacade(screenshot, appYOffset):
                state.appYOffset = appYOffset
                state.appFacade = screenshot
                state.stage = .preparingApp
            case let .didPrepareApp(screenshot):
                state.stage = .recognizingStrings(screenshot: screenshot)
            case .didFinish:
                state.stage = .resettingApp(yOffset: state.appYOffset)
            case .didResetApp:
                state = .init()
            case .delegate:
                return
            }
        }
    }

    package static func feedback() -> FeedbackOf<Self> {
        .combine(
            .state(\.stage) { stage, _, dependencies in
                switch stage {
                case .preparingFacade:
                    guard let screenshot = dependencies.windowService.screenshotAppWindow() else {
                        return .send(.didFinish(.failure(.screenshotFailed)))
                    }

                    let appYOffset = dependencies.windowService.appYOffset

                    return .send(.didPrepareFacade(screenshot: screenshot, appYOffset: appYOffset))
                case .preparingApp:
                    dependencies.windowService.resetAppPosition()
                    dependencies.appViewModel.refresh() // refresh app views with scrambled text

                    guard let screenshot = dependencies.windowService.screenshotAppWindow() else {
                        return .send(.didFinish(.failure(.screenshotFailed)))
                    }

                    return .send(.didPrepareApp(screenshot: screenshot))
                case let .recognizingStrings(screenshot):
                    return .publish(
                        dependencies.stringRecognizer
                            .recognizeStrings(in: screenshot)
                            .mapError(Error.recognitionFailed)
                            .mapToResult()
                            .map(Event.didFinish)
                            .eraseToAnyPublisher()
                    )
                case let .resettingApp(appYOffset):
                    dependencies.windowService.positionApp(yOffset: appYOffset, animationDuration: 0)
                    dependencies.appViewModel.refresh() // refresh app views with unscrambled text
                    return .send(.didResetApp)
                case .none:
                    return .none
                }
            },
            .event(/Event.didFinish) { payload, _, _ in
                .send(.delegate(.didFinish(payload)))
            }
        )
    }
}

package struct RecognitionFeatureView: View {
    package let store: StoreOf<RecognitionFeature>

    package init(store: StoreOf<RecognitionFeature>) {
        self.store = store
    }

    package var body: some View {
        WithViewStore(store) { store in
            if let appFacade = store.appFacade {
                Image(uiImage: appFacade)
                    .ignoresSafeArea()
            }
        }
    }
}
