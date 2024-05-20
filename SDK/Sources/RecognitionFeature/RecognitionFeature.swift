// RecognitionFeature.swift

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
    }

    package static func reducer() -> Reducer<State, Event> {
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
            }
        }
    }

    static var feedbacks: [Feedback<State, Event, Dependencies>] {
        [
            .lensing(state: \.stage) { stage, dependencies in
                switch stage {
                case .preparingFacade:
                    guard let screenshot = dependencies.windowService.screenshotAppWindow() else {
                        return .didFinish(.failure(.screenshotFailed))
                    }

                    let appYOffset = dependencies.windowService.appYOffset

                    return .didPrepareFacade(
                        screenshot: screenshot,
                        appYOffset: appYOffset
                    )
                case .preparingApp:
                    dependencies.windowService.resetAppPosition()
                    dependencies.appViewModel.refresh() // refresh app views with scrambled text

                    guard let screenshot = dependencies.windowService.screenshotAppWindow() else {
                        return .didFinish(.failure(.screenshotFailed))
                    }

                    return .didPrepareApp(screenshot: screenshot)
                case let .recognizingStrings(screenshot):
                    do {
                        let recognizedStrings = try await dependencies.stringRecognizer
                            .recognizeStrings(in: screenshot)
                        return .didFinish(.success(recognizedStrings))
                    } catch {
                        return .didFinish(.failure(.recognitionFailed(error)))
                    }
                case let .resettingApp(appYOffset):
                    dependencies.windowService.positionApp(yOffset: appYOffset, animationDuration: 0)
                    dependencies.appViewModel.refresh() // refresh app views with unscrambled text
                    return .didResetApp
                }
            }
        ]
    }
}

package struct RecognitionFeatureView: View {
    package let store: StoreOf<RecognitionFeature>

    package init(store: StoreOf<RecognitionFeature>) {
        self.store = store
    }

    package var body: some View {
        WithContextView(store: store) { context in
            if let appFacade = context.appFacade {
                Image(uiImage: appFacade)
                    .ignoresSafeArea()
            }
        }
    }
}
