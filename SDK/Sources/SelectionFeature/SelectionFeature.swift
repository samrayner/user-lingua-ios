// SelectionFeature.swift

import CasePaths
import Combine
import CombineFeedback
import Dependencies
import Foundation
import InspectionFeature
import Models
import RecognitionFeature
import SwiftUI
import Theme
import Utilities

public enum SelectionFeature: Feature {
    public struct Dependencies: Child {
        public typealias Parent = AllDependencies

        let deviceOrientationObservable: DeviceOrientationObservable
        let windowService: any WindowServiceProtocol
        let contentSizeCategoryService: any ContentSizeCategoryServiceProtocol

        // sourcery:begin: initFromParent
        let inspection: InspectionFeature.Dependencies
        let recognition: RecognitionFeature.Dependencies
        // sourcery:end
    }

    public struct State: Equatable {
        public var recognition = RecognitionFeature.State()
        public var inspection: InspectionFeature.State?
        var recognizedStrings: [RecognizedString]?

        public init() {}

        var isInspecting: Bool {
            inspection != nil
        }
    }

    public enum Event {
        case didSelectString(RecognizedString)
        case didTapOverlay
        case inspectionDidDismiss
        case setInspection(InspectionFeature.State?)
        case onAppear
        case orientationDidChange(UIDeviceOrientation)
        case inspection(InspectionFeature.Event)
        case recognition(RecognitionFeature.Event)
        case delegate(Delegate)

        public enum Delegate {
            case dismiss
        }
    }

    public static func reducer() -> ReducerOf<Self> {
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
                case let .recognition(.delegate(.didRecognizeString(recognizedString))):
                    state.recognizedStrings?.append(recognizedString)
                case let .recognition(.delegate(.didFinish(.failure(error)))):
                    switch error {
                    case .screenshotFailed:
                        // TODO: Handle recognition error
                        print("Recognition failed: screenshot error")
                        return
                    case let .recognitionFailed(error):
                        // TODO: Handle recognition error
                        print("Recognition failed: \(error)")
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

    private static var eventFeedbacks: [FeedbackOf<Self>] {
        [
            .event(/Event.didSelectString) { recognizedString, _, dependencies in
                ThemeFont.scaleFactor = dependencies.contentSizeCategoryService.systemContentSizeCategory.fontScaleFactor
                let inspectionState = InspectionFeature.State(
                    recognizedString: recognizedString,
                    screenshot: dependencies.windowService.screenshotAppWindow(),
                    appIsInDarkMode: dependencies.windowService.appUIStyle == .dark
                )
                return .combine(
                    .send(.recognition(.cancel)),
                    .send(.setInspection(inspectionState))
                )
            },
            .event(/Event.inspectionDidDismiss) { _, _, _ in
                .send(.delegate(.dismiss))
            },
            .event(/Event.didTapOverlay) { _, state, _ in
                if state.new.recognition.isInProgress {
                    .combine(
                        .send(.recognition(.cancel)),
                        .send(.delegate(.dismiss), after: 0.6)
                    )
                } else {
                    .send(.delegate(.dismiss))
                }
            },
            .event(/Event.onAppear) { _, _, _ in
                .send(.recognition(.start))
            },
            .event(/Event.orientationDidChange) { _, state, _ in
                if state.new.recognition.isInProgress {
                    .combine(
                        .send(.recognition(.cancel)),
                        .send(.recognition(.start), after: 0.6)
                    )
                } else {
                    .send(.recognition(.start))
                }
            }
        ]
    }

    public static var feedbacks: [FeedbackOf<Self>] {
        [
            RecognitionFeature.feedback.pullback(
                state: \.recognition,
                event: /Event.recognition,
                dependencies: \.recognition
            ),
            InspectionFeature.feedback.optional().pullback(
                state: \.inspection,
                event: /Event.inspection,
                dependencies: \.inspection
            )
        ] +
            eventFeedbacks
    }
}

public struct SelectionFeatureView: View {
    typealias Event = SelectionFeature.Event

    @EnvironmentObject var deviceOrientationObservable: DeviceOrientationObservable
    @Environment(\.colorScheme) private var colorScheme
    private let store: StoreOf<SelectionFeature>
    @State private var isVisible = false

    public init(store: StoreOf<SelectionFeature>) {
        self.store = store
    }

    struct BodyState: Equatable, Child {
        typealias Parent = SelectionFeature.State
        let recognizedStrings: [RecognizedString]?
        let isInspecting: Bool
    }

    public var body: some View {
        WithViewStore(store, scoped: BodyState.init) { state in
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
            .onReceive(deviceOrientationObservable.didChangePublisher) {
                if !store.state.isInspecting {
                    store.send(.orientationDidChange($0))
                }
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
                .animation(.bouncy, value: isVisible)
        }
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
    }
}
