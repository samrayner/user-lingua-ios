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
    }

    public struct Dependencies: Scoped {
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

        public init() {}

        public var isTakingScreenshot: Bool {
            stage == .preparingApp
        }
    }

    public enum Event {
        case start
        case didPrepareFacade(screenshot: UIImage, appYOffset: CGFloat)
        case didPrepareApp
        case didFinish(Result<[RecognizedString], Error>)
        case didResetApp
        case delegate(Delegate)

        public enum Delegate {
            case didFinish(Result<[RecognizedString], Error>)
        }
    }

    public static func reducer() -> ReducerOf<Self> {
        .init { state, event in
            switch event {
            case .start:
                state.stage = .preparingFacade
            case let .didPrepareFacade(screenshot, appYOffset):
                state.appYOffset = appYOffset
                state.appFacade = screenshot
                state.stage = .preparingApp
            case .didPrepareApp:
                state.stage = .recognizingStrings
            case .didFinish:
                state.stage = .resettingApp(yOffset: state.appYOffset)
            case .didResetApp:
                state = .init()
            case .delegate:
                return
            }
        }
    }

    public static var feedback: FeedbackOf<Self> {
        .combine(
            .state(scoped: \.stage) { state, dependencies in
                switch state.new {
                case .preparingFacade:
                    guard let screenshot = dependencies.windowService.screenshotAppWindow() else {
                        return .send(.didFinish(.failure(.screenshotFailed)))
                    }

                    let appYOffset = dependencies.windowService.appYOffset

                    return .send(.didPrepareFacade(screenshot: screenshot, appYOffset: appYOffset))
                case .preparingApp:
                    dependencies.windowService.resetAppPosition()
                    dependencies.appViewModel.refresh() // refresh app views with scrambled text
                    return .send(.didPrepareApp, after: 0.4) // give UI time to refresh (scramble)
                case .recognizingStrings:
                    guard let screenshot = dependencies.windowService.screenshotAppWindow() else {
                        return .send(.didFinish(.failure(.screenshotFailed)))
                    }

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
                    return .send(.didResetApp, after: 0.4) // give UI time to refresh (unscramble)
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
