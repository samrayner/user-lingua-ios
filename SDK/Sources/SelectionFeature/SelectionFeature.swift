// SelectionFeature.swift

import CasePaths
import Combine
import CombineFeedback
import Core
import Dependencies
import Foundation
import InspectionFeature
import RecognitionFeature
import SwiftUI
import Theme

package enum SelectionFeature: Feature {
    package struct Dependencies {
        let windowService: any WindowServiceProtocol
        let contentSizeCategoryService: any ContentSizeCategoryServiceProtocol
        let orientationService: any OrientationServiceProtocol

        let inspection: InspectionFeature.Dependencies
        let recognition: RecognitionFeature.Dependencies
    }

    package struct State: Equatable {
        package var recognition = RecognitionFeature.State()
        package var inspection: InspectionFeature.State?
        var recognizedStrings: [RecognizedString]?

        package init() {}

        var isInspecting: Bool {
            inspection != nil
        }
    }

    package enum Event {
        case didSelectString(RecognizedString)
        case didTapOverlay
        case inspectionDidDismiss
        case setInspection(InspectionFeature.State?)
        case onAppear
        case orientationDidChange(UIDeviceOrientation)
        case inspection(InspectionFeature.Event)
        case recognition(RecognitionFeature.Event)
        case delegate(Delegate)

        package enum Delegate {
            case dismiss
        }
    }

    package static func reducer() -> ReducerOf<Self> {
        .combine(
            RecognitionFeature.reducer()
                .pullback(state: \State.recognition, event: /Event.recognition),

            InspectionFeature.reducer()
                .optional()
                .pullback(state: \State.inspection, event: /Event.inspection),

            ReducerOf<Self> { state, event in
                switch event {
                case let .setInspection(inspectionState):
                    state.inspection = inspectionState
                    state.recognizedStrings = nil
                case .onAppear:
                    state.recognizedStrings = []
                case .orientationDidChange:
                    state.recognizedStrings = []
                case let .recognition(.delegate(.didFinish(result))):
                    switch result {
                    case let .success(recognizedStrings):
                        state.recognizedStrings = recognizedStrings
                    case .failure:
                        // TODO: recognition error handling
                        print("RECOGNITION FAILED")
                        return
                    }
                case .inspection,
                     .recognition,
                     .delegate,
                     .didSelectString,
                     .didTapOverlay,
                     .inspectionDidDismiss:
                    return
                }
            }
        )
    }

    private static var eventFeedback: FeedbackOf<Self> {
        .combine(
            .event(/Event.didSelectString) { recognizedString, _, dependencies in
                ThemeFont.scaleFactor = dependencies.contentSizeCategoryService.systemContentSizeCategory.fontScaleFactor
                let inspectionState = InspectionFeature.State(
                    recognizedString: recognizedString,
                    appFacade: dependencies.windowService.screenshotAppWindow(),
                    appIsInDarkMode: dependencies.windowService.appUIStyle == .dark
                )
                return .send(.setInspection(inspectionState))
            },
            .event(/Event.didTapOverlay) { _, _, _ in
                .send(.delegate(.dismiss))
            },
            .event(/Event.inspectionDidDismiss) { _, _, _ in
                .send(.delegate(.dismiss))
            },
            .event(/Event.onAppear) { _, _, _ in
                .send(.recognition(.start))
            },
            .event(/Event.orientationDidChange) { _, state, _ in
                guard state.inspection == nil else { return .none }
                return .send(.recognition(.start), after: 0.1)
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
            InspectionFeature.feedback.optional().pullback(
                state: \.inspection,
                event: /Event.inspection,
                dependencies: \.inspection
            ),
            eventFeedback
        )
    }
}

package struct SelectionFeatureView: View {
    typealias Event = SelectionFeature.Event

    @EnvironmentObject var orientationService: ViewDependency<OrientationServiceProtocol>
    @Environment(\.colorScheme) private var colorScheme
    private let store: StoreOf<SelectionFeature>
    @State private var isVisible = false

    package init(store: StoreOf<SelectionFeature>) {
        self.store = store
    }

    struct BodyState: Equatable, Scoped {
        typealias Parent = SelectionFeature.State
        let recognizedStrings: [RecognizedString]?
        let isInspecting: Bool
    }

    package var body: some View {
        WithViewStore(store, scope: BodyState.init) { state in
            ZStack(alignment: .topLeading) {
                if state.recognizedStrings != nil {
                    Color.theme(\.overlay)
                        .opacity(isVisible ? .Opacity.light : .Opacity.transparent)
                        .mask {
                            ZStack {
                                Color(.white)
                                highlights(color: .black)
                            }
                            .compositingGroup()
                            .luminanceToAlpha()
                        }
                        .onTapGesture { store.send(.didTapOverlay) }
                        .animation(.smooth, value: isVisible)
                        .onAppear { isVisible = true }
                        .onDisappear { isVisible = false }

                    highlights(
                        color: .interactableClear,
                        onSelectString: { store.send(.didSelectString($0)) }
                    )
                }
            }
            .ignoresSafeArea()
            .background {
                RecognitionFeatureView(store: store.scoped(to: \.recognition, event: Event.recognition))
            }
            .onAppear {
                store.send(.onAppear)
            }
            .onReceive(orientationService.dependency.orientationDidChange()) {
                store.send(.orientationDidChange($0))
            }
            .fullScreenCover(
                store: store,
                get: \.inspection,
                set: Event.setInspection,
                event: Event.inspection,
                onDismiss: Event.inspectionDidDismiss
            ) { store in
                InspectionFeatureView(store: store)
                    .preferredColorScheme(colorScheme == .light ? .dark : .light)
            }
        }
    }

    func highlights(color: Color, onSelectString: @escaping (RecognizedString) -> Void = { _ in }) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(store.state.recognizedStrings ?? []) { recognizedString in
                RecognizedStringHighlight(
                    recognizedString: recognizedString,
                    color: color
                )
                .onTapGesture { onSelectString(recognizedString) }
            }
        }
        .ignoresSafeArea()
    }
}

private struct RecognizedStringHighlight: View {
    @State private var isVisible = false
    let recognizedString: RecognizedString
    let color: Color

    var body: some View {
        ForEach(recognizedString.lines) { line in
            color
                .cornerRadius(5)
                .frame(width: line.boundingBox.width + 20, height: line.boundingBox.height + 20)
                .position(x: line.boundingBox.midX, y: line.boundingBox.midY)
                .scaleEffect(isVisible ? 1 : 2)
                .opacity(isVisible ? .Opacity.opaque : .Opacity.transparent)
                .animation(.bouncy.delay(.random(in: 0 ... TimeInterval.AnimationDuration.quick)), value: isVisible)
        }
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
    }
}

extension SelectionFeature.Dependencies {
    package init(dependencies: AllDependencies) {
        self.windowService = dependencies.windowService
        self.contentSizeCategoryService = dependencies.contentSizeCategoryService
        self.orientationService = dependencies.orientationService

        self.inspection = .init(dependencies: dependencies)
        self.recognition = .init(dependencies: dependencies)
    }
}
