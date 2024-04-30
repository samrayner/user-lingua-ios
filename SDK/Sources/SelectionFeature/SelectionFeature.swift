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
        package var recognition = RecognitionFeature.State()
        var recognizedStrings: [RecognizedString]?

        @Presents package var inspection: InspectionFeature.State?

        package init() {}
    }

    package enum Action: BindableAction {
        case didSelectString(RecognizedString)
        case inspectionDidDismiss
        case onAppear
        case observeDeviceRotation
        case deviceOrientationDidChange
        case inspection(PresentationAction<InspectionFeature.Action>)
        case recognition(RecognitionFeature.Action)
        case binding(BindingAction<State>)
        case delegate(Delegate)
    }

    @CasePathable
    package enum Delegate {
        case inspectionDidDismiss
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
                return .none
            case .inspectionDidDismiss:
                return .run { send in
                    await send(.delegate(.inspectionDidDismiss))
                }
            case .onAppear:
                state.recognizedStrings = []
                return .run { send in
                    await send(.recognition(.start))
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

                    for await _ in stream {
                        await send(.deviceOrientationDidChange)
                    }
                }
            case .deviceOrientationDidChange:
                state.recognizedStrings = nil
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

    package init(store: StoreOf<SelectionFeature>) {
        self.store = store
    }

    package var body: some View {
        WithPerceptionTracking {
            ZStack(alignment: .topLeading) {
                if store.recognizedStrings != nil {
                    Color.theme(\.overlay)
                        .opacity(.Opacity.light)
                        .mask {
                            ZStack {
                                Color(.white)
                                highlights(color: .black)
                            }
                            .compositingGroup()
                            .luminanceToAlpha()
                        }

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
            .task { await store.send(.observeDeviceRotation).finish() }
        }
    }

    func highlights(color: Color, onSelectString: @escaping (RecognizedString) -> Void = { _ in }) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(store.recognizedStrings ?? []) { recognizedString in
                ForEach(recognizedString.lines) { line in
                    color
                        .cornerRadius(5)
                        .frame(width: line.boundingBox.width + 20, height: line.boundingBox.height + 20)
                        .position(x: line.boundingBox.midX, y: line.boundingBox.midY)
                        .onTapGesture {
                            onSelectString(recognizedString)
                        }
                }
            }
        }
        .ignoresSafeArea()
    }
}
