// RecognitionFeature.swift

import CasePaths
import Combine
import CombineFeedback
import Dependencies
import Foundation
import Models
import SwiftUI
import UIKit
import Utilities

public enum RecognitionFeature: Feature {
    public enum Error: Swift.Error, Equatable {
        case screenshotFailed
        case recognitionFailed(Swift.Error)
        case cancelled
    }

    public struct Dependencies: Child {
        public typealias Parent = AllDependencies

        let windowService: any WindowServiceProtocol
        let appViewModel: UserLinguaObservable
        let stringRecognizer: any StringRecognizerProtocol
    }

    public enum Stage: Equatable {
        case preparingFacade
        case preparingApp
        case recognizingStrings
        case resettingApp(yOffset: CGFloat)
    }

    public struct State: Equatable {
        public var stage: Stage?
        var appFacade: UIImage?
        var appYOffset: CGFloat = 0
        var isCancelling = false
        var result: Result<[RecognizedString], RecognitionFeature.Error> = .success([])

        public init() {}

        public var isTakingScreenshot: Bool {
            stage == .preparingApp
        }
    }

    public enum Event {
        case start
        case cancel
        case didPrepareFacade(screenshot: UIImage, appYOffset: CGFloat)
        case didPrepareApp
        case didRecognizeStrings([RecognizedString])
        case didFinishRecognizingStrings(Result<[RecognizedString], Error>)
        case didResetApp
        case delegate(Delegate)

        public enum Delegate {
            case didRecognizeStrings([RecognizedString])
            case didFinish(Result<[RecognizedString], Error>)
        }
    }

    public static func reducer() -> ReducerOf<Self> {
        .init { state, event in
            switch event {
            case .start:
                state.stage = .preparingFacade
            case .cancel:
                state.isCancelling = true
            case let .didPrepareFacade(screenshot, appYOffset):
                state.appYOffset = appYOffset
                state.appFacade = screenshot
                state.stage = .preparingApp
            case .didPrepareApp:
                state.stage = .recognizingStrings
            case let .didFinishRecognizingStrings(result):
                state.stage = .resettingApp(yOffset: state.appYOffset)
                state.result = result
            case .didResetApp:
                state = .init()
            case .didRecognizeStrings, .delegate:
                return
            }
        }
    }

    public static var feedbacks: [FeedbackOf<Self>] {
        [
            .state(ifChanged: \.stage) { state, dependencies in
                switch state.new.stage {
                case .preparingFacade:
                    guard let screenshot = dependencies.windowService.screenshotAppWindow() else {
                        return .send(.didFinishRecognizingStrings(.failure(.screenshotFailed)))
                    }

                    let appYOffset = dependencies.windowService.appYOffset

                    return .send(.didPrepareFacade(screenshot: screenshot, appYOffset: appYOffset))
                case .preparingApp:
                    dependencies.windowService.resetAppPosition()
                    dependencies.appViewModel.refresh() // refresh app views with scrambled text
                    return .send(.didPrepareApp, after: 0.4) // give UI time to refresh (scramble)
                case .recognizingStrings:
                    guard !state.new.isCancelling else {
                        return .send(.didFinishRecognizingStrings(.failure(.cancelled)))
                    }

                    guard let screenshot = dependencies.windowService.screenshotAppWindow() else {
                        return .send(.didFinishRecognizingStrings(.failure(.screenshotFailed)))
                    }

                    return .publish(
                        dependencies.stringRecognizer
                            .recognizeStrings(in: screenshot)
                            .mapError(Error.recognitionFailed)
                            .mapToEvents(
                                output: Event.didRecognizeStrings,
                                failure: { Event.didFinishRecognizingStrings(.failure($0)) },
                                finished: { lastValue in
                                    Event.didFinishRecognizingStrings(.success(lastValue ?? []))
                                }
                            )
                            .receive(on: DispatchQueue.main)
                            .eraseToAnyPublisher()
                    )
                case let .resettingApp(appYOffset):
                    dependencies.windowService.positionApp(yOffset: appYOffset, animationDuration: 0)
                    dependencies.appViewModel.refresh() // refresh app views with unscrambled text
                    return .send(.didResetApp, after: 0.4) // give UI time to refresh (unscramble)
                case .none:
                    return .none
                }
            },
            .event(/Event.didRecognizeStrings) { payload, _, _ in
                .send(.delegate(.didRecognizeStrings(payload)))
            },
            .event(/Event.didResetApp) { _, state, _ in
                .send(.delegate(.didFinish(state.old.result)))
            },
            .event(/Event.cancel) { _, _, dependencies in
                dependencies.stringRecognizer.cancel()
                return .none
            }
        ]
    }
}

public struct RecognitionFeatureView: View {
    public let store: StoreOf<RecognitionFeature>

    public init(store: StoreOf<RecognitionFeature>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store, scoped: \.appFacade) { appFacade in
            if let appFacade = appFacade.state {
                Image(uiImage: appFacade)
                    .ignoresSafeArea()
            }
        }
    }
}
