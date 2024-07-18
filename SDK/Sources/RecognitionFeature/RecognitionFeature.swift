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
        case recognitionFailed(StringRecognizerError)
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
        case screenshottingApp
        case resettingApp
        case recognizingStrings
    }

    public struct State: Equatable {
        var stage: Stage?
        var appFacade: UIImage?
        var recognizableScreenshot: UIImage?
        var appYOffset: CGFloat = 0
        var recognizedStrings: [RecognizedString] = []
        var isCancelled = false

        public init() {}

        public var isScreenshottingForRecognition: Bool {
            [.preparingApp, .screenshottingApp].contains(stage)
        }

        public var isInProgress: Bool {
            stage != nil
        }
    }

    public enum Event {
        case start
        case cancel
        case didPrepareFacade(screenshot: UIImage, appYOffset: CGFloat)
        case didPrepareApp
        case didScreenshotApp(UIImage)
        case didResetApp
        case didRecognizeString(RecognizedString)
        case didFinishRecognizingStrings(Result<Void, Error>)
        case delegate(Delegate)

        public enum Delegate {
            case didRecognizeString(RecognizedString)
            case didFinish(Result<[RecognizedString], Error>)
        }
    }

    public static func reducer() -> ReducerOf<Self> {
        .init { state, event in
            switch event {
            case .cancel:
                state.isCancelled = true
            case .start:
                state.stage = .preparingFacade
            case let .didPrepareFacade(screenshot, appYOffset):
                state.appYOffset = appYOffset
                state.appFacade = screenshot
                state.stage = .preparingApp
            case .didPrepareApp:
                state.stage = .screenshottingApp
            case let .didScreenshotApp(screenshot):
                state.appFacade = nil
                state.recognizableScreenshot = screenshot
                state.stage = .resettingApp
            case .didResetApp:
                state.appFacade = nil
                state.stage = .recognizingStrings
            case let .didRecognizeString(recognizedString):
                state.recognizedStrings.append(recognizedString)
            case .didFinishRecognizingStrings:
                state = .init()
            case .delegate:
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
                    dependencies.appViewModel.refresh() // refresh app views with recognizable (scrambled) text
                    return .send(.didPrepareApp, after: 0.3) // give UI time to refresh (scramble)
                case .screenshottingApp:
                    guard let screenshot = dependencies.windowService.screenshotAppWindow() else {
                        return .send(.didFinishRecognizingStrings(.failure(.screenshotFailed)))
                    }
                    return .send(.didScreenshotApp(screenshot))
                case .resettingApp:
                    dependencies.windowService.positionApp(yOffset: state.new.appYOffset, animationDuration: 0)
                    dependencies.appViewModel.refresh() // refresh app views with unscrambled text
                    return .send(.didResetApp, after: 0.3) // give UI time to refresh (unscramble)
                case .recognizingStrings:
                    guard let screenshot = state.new.recognizableScreenshot else {
                        return .send(.didFinishRecognizingStrings(.failure(.recognitionFailed(.invalidImage))))
                    }

                    guard !state.new.isCancelled else {
                        return .send(.didFinishRecognizingStrings(.success()))
                    }

                    return .publish(
                        dependencies.stringRecognizer
                            .recognizeStrings(in: screenshot)
                            .mapError(Error.recognitionFailed)
                            .map(Event.didRecognizeString)
                            .append(Event.didFinishRecognizingStrings(.success()))
                            .catch { Just(Event.didFinishRecognizingStrings(.failure($0))) }
                            .receive(on: DispatchQueue.main)
                            .eraseToAnyPublisher()
                    )
                case nil:
                    return .none
                }
            },
            .event(/Event.didRecognizeString) { payload, _, _ in
                .send(.delegate(.didRecognizeString(payload)))
            },
            .event(/Event.didFinishRecognizingStrings) { result, state, _ in
                .send(.delegate(.didFinish(
                    result.map { _ in state.old.recognizedStrings }
                )))
            },
            .event(/Event.cancel) { _, state, dependencies in
                if state.new.stage == .recognizingStrings {
                    dependencies.stringRecognizer.cancel()
                }
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
