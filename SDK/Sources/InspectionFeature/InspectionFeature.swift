// InspectionFeature.swift

import CasePaths
import Combine
import CombineFeedback
import Core
import Dependencies
import Diff
import Foundation
import RecognitionFeature
import Strings
import SwiftUI
import Theme

package enum InspectionFeature: Feature {
    package struct Dependencies: Scoped {
        package typealias Parent = AllDependencies

        let appViewModel: UserLinguaObservable
        let notificationCenter: NotificationCenter
        let deviceOrientationObservable: DeviceOrientationObservable
        let windowService: any WindowServiceProtocol
        let contentSizeCategoryService: any ContentSizeCategoryServiceProtocol
        let suggestionsRepository: any SuggestionsRepositoryProtocol

        // sourcery: initFromParent
        let recognition: RecognitionFeature.Dependencies
    }

    package enum Field: String, Hashable {
        case suggestion
    }

    package enum PreviewMode: String, CaseIterable {
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

    package enum PresentationState: Equatable {
        case presenting(appFacade: UIImage?)
        case presented
        case preparingToDismiss
        case dismissing(appFacade: UIImage?)
    }

    package struct State: Equatable {
        package internal(set) var recognizedString: RecognizedString
        package var locale = Locale.current
        package var suggestionValue: String
        var appIsInDarkMode: Bool
        var presentation: PresentationState
        var recognition = RecognitionFeature.State()
        var previewMode: PreviewMode = .app
        var focusedField: Field?
        var keyboardAnimation: Animation?
        var keyboardHeight: CGFloat = 0
        var viewportFrame: CGRect = .zero
        var isFullScreen = false

        package var isTransitioning: Bool {
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

        package init(
            recognizedString: RecognizedString,
            appFacade: UIImage?,
            appIsInDarkMode: Bool
        ) {
            self.recognizedString = recognizedString
            self.suggestionValue = recognizedString.value
            self.presentation = .presenting(appFacade: appFacade)
            self.appIsInDarkMode = appIsInDarkMode
        }

        func makeSuggestion() -> Suggestion {
            .init(
                recordedString: recognizedString.recordedString,
                newValue: suggestionValue,
                locale: locale
            )
        }
    }

    package enum Event {
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
        case dismiss(appFacade: UIImage?)
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

    package static func reducer() -> ReducerOf<Self> {
        .combine(
            RecognitionFeature.reducer()
                .pullback(state: \State.recognition, event: /Event.recognition),

            ReducerOf<Self> { state, event in
                switch event {
                case .didTapSuggestionPreview:
                    state.focusedField = .suggestion
                case .didTapClose:
                    state.presentation = .preparingToDismiss
                case .didTapDoneSuggesting:
                    state.focusedField = nil
                case .didTapToggleDarkMode:
                    state.appIsInDarkMode.toggle()
                case .didTapSubmit:
                    print("SUBMITTED \(state.suggestionValue)")
                case .didTapToggleFullScreen:
                    state.focusedField = nil
                    state.isFullScreen.toggle()
                case .didAppear:
                    state.presentation = .presented
                case let .dismiss(appFacade):
                    state.presentation = .dismissing(appFacade: appFacade)
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
                case let .recognition(.delegate(.didFinish(result))):
                    switch result {
                    case let .success(recognizedStrings):
                        guard let recognizedString = recognizedStrings.first(
                            where: { $0.recordedString.formatted == state.recognizedString.recordedString.formatted }
                        ) else { return }

                        // recognizedString may not be found again on re-recognition
                        // due to keyboard avoidance in the app hiding it from view

                        state.recognizedString = recognizedString
                    case .failure:
                        // recognition failed for some reason, so do nothing
                        return
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

    private static var stateFeedback: FeedbackOf<Self> {
        .combine(
            .state(scoped: \.presentation) { state, dependencies in
                switch state.new {
                case .preparingToDismiss:
                    let appFacade = dependencies.windowService.screenshotAppWindow()
                    dependencies.contentSizeCategoryService.resetAppContentSizeCategory()
                    dependencies.windowService.resetAppWindow()
                    dependencies.appViewModel.refresh() // rerun UserLingua.shared.displayString
                    return .send(.dismiss(appFacade: appFacade))
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
                .send(.saveSuggestion) // TODO: debounce
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
        )
    }

    private static var eventFeedback: FeedbackOf<Self> {
        .combine(
            .event(/Event.didTapDecreaseTextSize) { _, _, dependencies in
                dependencies.contentSizeCategoryService.decrementAppContentSizeCategory()
                return .none
            },
            .event(/Event.didTapIncreaseTextSize) { _, _, dependencies in
                dependencies.contentSizeCategoryService.incrementAppContentSizeCategory()
                return .none
            },
            .event(/Event.orientationDidChange) { _, _, _ in
                .send(.recognition(.start), after: 0.1)
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
        )
    }

    package static var feedback: FeedbackOf<Self> {
        .combine(
            RecognitionFeature.feedback.pullback(
                state: \.recognition,
                event: /Event.recognition,
                dependencies: \.recognition
            ),
            stateFeedback,
            eventFeedback
        )
    }
}
