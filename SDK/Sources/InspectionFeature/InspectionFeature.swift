// InspectionFeature.swift

import CasePaths
import Combine
import CombineFeedback
import Dependencies
import Diff
import Foundation
import Models
import RecognitionFeature
import Strings
import SwiftUI
import Theme
import Utilities

public enum InspectionFeature: Feature {
    public struct Dependencies: Child {
        public typealias Parent = AllDependencies

        let appViewModel: UserLinguaObservable
        let notificationCenter: NotificationCenter
        let deviceOrientationObservable: DeviceOrientationObservable
        let windowService: any WindowServiceProtocol
        let contentSizeCategoryService: any ContentSizeCategoryServiceProtocol
        let suggestionsRepository: any SuggestionsRepositoryProtocol

        // sourcery: initFromParent
        let recognition: RecognitionFeature.Dependencies
    }

    public enum Field: String, Hashable {
        case suggestion
    }

    public enum PreviewMode: String, CaseIterable {
        case text
        case app

        var icon: Image {
            switch self {
            case .text:
                Image.theme(\.textPreviewMode)
            case .app:
                Image.theme(\.appPreviewMode)
            }
        }
    }

    public struct AppFacade: Equatable {
        let screenshot: UIImage
        let yOffset: CGFloat
    }

    public enum PresentationState: Equatable {
        case presenting(appFacade: AppFacade?)
        case presented
        case preparingAppFacadeForDismissal
        case preparingAppForDismissal(appFacade: AppFacade?)
        case dismissing(appFacade: AppFacade?)

        var appFacade: AppFacade? {
            switch self {
            case .presented, .preparingAppFacadeForDismissal:
                nil
            case let .presenting(appFacade),
                 let .preparingAppForDismissal(appFacade),
                 let .dismissing(appFacade):
                appFacade
            }
        }
    }

    public struct State: Equatable {
        public internal(set) var recognizedString: RecognizedString
        public var locale = Locale.current
        public var suggestionValue: String
        public var recognition = RecognitionFeature.State()
        var appIsInDarkMode: Bool
        var previewMode: PreviewMode = .app
        var focusedField: Field?
        var keyboardAnimation: Animation?
        var keyboardHeight: CGFloat = 0
        var viewportFrame: CGRect = .zero
        var isFullScreen = false
        var presentation: PresentationState

        public var isTransitioning: Bool {
            presentation != .presented
        }

        var localizedValue: String {
            recognizedString.localizedValue(locale: locale)
        }

        var diff: AttributedString {
            .init(
                old: localizedValue,
                new: suggestionValue,
                diffAttributes: .init(
                    insert: [
                        .foregroundColor: UIColor.theme(\.diffInsertion),
                        .underlineColor: UIColor.theme(\.diffInsertion),
                        .underlineStyle: NSUnderlineStyle.single.rawValue
                    ],
                    delete: [
                        .foregroundColor: UIColor.theme(\.diffDeletion),
                        .strikethroughColor: UIColor.theme(\.diffDeletion),
                        .strikethroughStyle: NSUnderlineStyle.single.rawValue
                    ]
                )
            )
        }

        var localizations: Set<String> {
            Set(recognizedString.localization?.bundle?.localizations ?? [])
                .filter { $0 != "Base" }
        }

        public init(
            recognizedString: RecognizedString,
            screenshot: UIImage?,
            appIsInDarkMode: Bool
        ) {
            self.recognizedString = recognizedString
            self.suggestionValue = recognizedString.value
            self.appIsInDarkMode = appIsInDarkMode
            self.presentation = .presenting(
                appFacade: screenshot.map { .init(screenshot: $0, yOffset: 0) }
            )
        }

        func makeSuggestion() -> Suggestion {
            .init(
                recordedString: recognizedString.recordedString,
                newValue: suggestionValue,
                locale: locale
            )
        }
    }

    public enum Event {
        case didTapSuggestionPreview
        case didTapClose
        case didTapDoneSuggesting
        case didTapSubmit
        case didTapIncreaseTextSize
        case didTapDecreaseTextSize
        case didTapToggleDarkMode
        case didTapToggleFullScreen
        case onAppear
        case didAppear
        case didPrepareAppFacadeForDismissal(AppFacade?)
        case didPrepareAppForDismissal
        case setPreviewMode(PreviewMode)
        case setSuggestionValue(String)
        case setFocusedField(Field?)
        case saveSuggestion
        case setLocale(identifier: String)
        case orientationDidChange(UIDeviceOrientation)
        case viewportFrameDidChange(CGRect)
        case focusViewport(fromZeroPosition: Bool = false)
        case keyboardWillChangeFrame(KeyboardNotification)
        case recognition(RecognitionFeature.Event)
    }

    public static func reducer() -> ReducerOf<Self> {
        .combine(
            RecognitionFeature.reducer()
                .pullback(state: \State.recognition, event: /Event.recognition),

            ReducerOf<Self> { state, event in
                switch event {
                case .didTapSuggestionPreview:
                    state.focusedField = .suggestion
                case .didTapDoneSuggesting:
                    state.focusedField = nil
                case .didTapToggleDarkMode:
                    state.appIsInDarkMode.toggle()
                case .didTapSubmit:
                    print("SUBMITTED \(state.suggestionValue)")
                case .didTapToggleFullScreen:
                    state.focusedField = nil
                    state.isFullScreen.toggle()
                case .didTapClose:
                    state.presentation = .preparingAppFacadeForDismissal
                case .didAppear:
                    state.presentation = .presented
                case let .didPrepareAppFacadeForDismissal(appFacade):
                    state.presentation = .preparingAppForDismissal(appFacade: appFacade)
                case .didPrepareAppForDismissal:
                    state.presentation = .dismissing(appFacade: state.presentation.appFacade)
                case let .setSuggestionValue(value):
                    state.suggestionValue = value
                case let .setLocale(identifier):
                    state.locale = .init(identifier: identifier)
                case let .setPreviewMode(previewMode):
                    state.previewMode = previewMode
                case let .setFocusedField(field):
                    state.focusedField = field
                case let .viewportFrameDidChange(frame):
                    state.viewportFrame = frame
                case let .keyboardWillChangeFrame(notification):
                    state.keyboardAnimation = notification.animation
                    let newHeight = max(0, UIScreen.main.bounds.height - notification.endFrame.origin.y)
                    if newHeight != state.keyboardHeight {
                        state.keyboardHeight = newHeight
                    }
                case let .recognition(.delegate(.didRecognizeString(recognizedString))):
                    // if we recognize the string being inspected again (e.g. on orientation change)
                    // update our state with its latest position to refocus the viewport
                    if recognizedString.recordedString.formatted == state.recognizedString.recordedString.formatted {
                        state.recognizedString = recognizedString
                    }
                case .didTapIncreaseTextSize,
                     .didTapDecreaseTextSize,
                     .onAppear,
                     .orientationDidChange,
                     .focusViewport,
                     .saveSuggestion,
                     .recognition:
                    return
                }
            }
        )
    }

    private static var stateFeedbacks: [FeedbackOf<Self>] {
        [
            .state(scoped: \.presentation) { presentation, dependencies in
                switch presentation.new {
                case .preparingAppFacadeForDismissal:
                    let screenshot = dependencies.windowService.screenshotAppWindow()
                    let appYOffset = dependencies.windowService.appYOffset
                    return .send(
                        .didPrepareAppFacadeForDismissal(
                            screenshot.map { AppFacade(screenshot: $0, yOffset: appYOffset) }
                        )
                    )
                case .preparingAppForDismissal:
                    dependencies.contentSizeCategoryService.resetAppContentSizeCategory()
                    dependencies.windowService.resetAppWindow()
                    dependencies.appViewModel.refresh() // rerun UserLinguaClient.shared.displayString
                    return .send(.didPrepareAppForDismissal, after: 0.3) // leave time for everything to reset
                case .presenting, .presented, .dismissing:
                    return .none
                }
            },
            .state(ifChanged: \.viewportFrame) { state, _ in
                guard !state.new.isTransitioning else { return .none }
                return .send(.focusViewport())
            },
            .state(ifChanged: \.recognizedString) { _, _ in
                // refocus viewport after re-recognition (i.e. after orientation change)
                .send(.focusViewport(fromZeroPosition: true))
            },
            .state(scoped: \.suggestionValue) { _, _ in
                .send(.saveSuggestion, after: 0.5) // debounce for 0.5s
            },
            .state(scoped: \.appIsInDarkMode) { _, dependencies in
                dependencies.windowService.toggleDarkMode()
                return .none
            },
            .state(ifChanged: \.locale) { state, dependencies in
                let suggestionValue = dependencies.suggestionsRepository.suggestion(
                    for: state.new.recognizedString.value,
                    locale: state.new.locale
                )?.newValue ?? state.new.localizedValue
                return .send(.setSuggestionValue(suggestionValue))
            }
        ]
    }

    private static var eventFeedbacks: [FeedbackOf<Self>] {
        [
            .event(/Event.didTapDecreaseTextSize) { _, _, dependencies in
                dependencies.contentSizeCategoryService.decrementAppContentSizeCategory()
                return .none
            },
            .event(/Event.didTapIncreaseTextSize) { _, _, dependencies in
                dependencies.contentSizeCategoryService.incrementAppContentSizeCategory()
                return .none
            },
            .event(/Event.orientationDidChange) { _, _, _ in
                .combine(
                    .send(.recognition(.cancel)),
                    .send(.recognition(.start), after: 0.5)
                )
            },
            .event(/Event.focusViewport) { fromZeroPosition, state, dependencies in
                if fromZeroPosition {
                    dependencies.windowService.resetAppPosition()
                }

                dependencies.windowService.positionApp(
                    focusing: state.new.recognizedString.boundingBoxCenter,
                    within: state.new.viewportFrame,
                    animationDuration: .AnimationDuration.quick
                )

                return .none
            },
            .event(/Event.onAppear) { _, _, _ in
                .send(.didAppear, after: .AnimationDuration.screenTransition)
            },
            .event(/Event.saveSuggestion) { _, state, dependencies in
                dependencies.suggestionsRepository.saveSuggestion(state.new.makeSuggestion())
                dependencies.appViewModel.refresh()
                return .none
            }
        ]
    }

    public static var feedbacks: [FeedbackOf<Self>] {
        [
            RecognitionFeature.feedback.pullback(
                state: \.recognition,
                event: /Event.recognition,
                dependencies: \.recognition
            )
        ]
            + stateFeedbacks
            + eventFeedbacks
    }
}
