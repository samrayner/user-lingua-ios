// SelectionFeature.swift

import AsyncAlgorithms
import ComposableArchitecture
import Core
import Foundation
import InspectionFeature
import RecognitionFeature
import SwiftUI
import Theme

@Reducer
package struct SelectionFeature {
    @Dependency(NotificationManagerDependency.self) var notificationManager
    @Dependency(WindowManagerDependency.self) var windowManager

    package init() {}

    @ObservableState
    package struct State: Equatable {
        @Shared(RecognitionFeature.State.persistenceKey) package var recognition = .init()
        var recognizedStrings: [RecognizedString]?
        var lastDeviceOrientation = UIDevice.current.orientation

        @Presents package var inspection: InspectionFeature.State?

        package init() {}
    }

    package enum Action: BindableAction {
        case didSelectString(RecognizedString)
        case didTapOverlay
        case inspectionDidDismiss
        case onAppear
        case observeDeviceRotation
        case deviceOrientationDidChange(UIDeviceOrientation)
        case inspection(PresentationAction<InspectionFeature.Action>)
        case recognition(RecognitionFeature.Action)
        case binding(BindingAction<State>)
        case delegate(Delegate)
    }

    @CasePathable
    package enum Delegate {
        case dismiss
    }

    enum CancelID {
        case deviceOrientationObservation
    }

    package var body: some ReducerOf<Self> {
        BindingReducer()

        Scope(state: \.recognition, action: \.recognition) {
            RecognitionFeature()
        }

        Reduce { state, action in
            switch action {
            case let .didSelectString(recognizedString):
                state.inspection = .init(
                    recognizedString: recognizedString,
                    darkModeIsEnabled: windowManager.appUIStyle == .dark,
                    appFacade: windowManager.screenshotAppWindow()
                )
                state.recognizedStrings = nil
                return .cancel(id: CancelID.deviceOrientationObservation)
            case .didTapOverlay, .inspectionDidDismiss:
                return .run { send in
                    await send(.delegate(.dismiss))
                }
            case .onAppear:
                state.recognizedStrings = []
                return .run { send in
                    await send(.recognition(.start))
                    await send(.observeDeviceRotation)
                }
            case .observeDeviceRotation:
                return .run { send in
                    let stream = await notificationManager
                        .observe(name: UIDevice.orientationDidChangeNotification)
                        .map { _ in await UIDevice.current.orientation }
                        .filter {
                            [.landscapeLeft, .landscapeRight, .portrait, .portraitUpsideDown].contains($0)
                        }
                        .removeDuplicates()

                    for await orientation in stream {
                        await send(.deviceOrientationDidChange(orientation))
                    }
                }
                .cancellable(id: CancelID.deviceOrientationObservation)
            case let .deviceOrientationDidChange(orientation):
                guard orientation != state.lastDeviceOrientation else { return .none }
                state.lastDeviceOrientation = orientation
                state.recognizedStrings = []
                return .run { send in
                    await send(.recognition(.start))
                }
            case let .recognition(.delegate(.didRecognizeStrings(recognizedStrings))):
                state.recognizedStrings = recognizedStrings
                return .none
            case .inspection, .recognition, .binding, .delegate:
                return .none
            }
        }
        .ifLet(\.$inspection, action: \.inspection) {
            InspectionFeature()
        }
    }
}

package struct SelectionFeatureView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Perception.Bindable package var store: StoreOf<SelectionFeature>
    @State private var isVisible = false

    package init(store: StoreOf<SelectionFeature>) {
        self.store = store
    }

    package var body: some View {
        WithPerceptionTracking {
            ZStack(alignment: .topLeading) {
                if store.recognizedStrings != nil {
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
                RecognitionFeatureView(store: store.scope(state: \.recognition, action: \.recognition))
            }
            .onAppear { store.send(.onAppear) }
            .fullScreenCover(
                item: $store.scope(state: \.inspection, action: \.inspection),
                onDismiss: { store.send(.inspectionDidDismiss) }
            ) { store in
                InspectionFeatureView(store: store)
                    .preferredColorScheme(colorScheme == .light ? .dark : .light)
            }
        }
    }

    func highlights(color: Color, onSelectString: @escaping (RecognizedString) -> Void = { _ in }) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(store.recognizedStrings ?? []) { recognizedString in
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
