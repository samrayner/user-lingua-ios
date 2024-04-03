// SelectionFeature.swift

import ComposableArchitecture
import Core
import Foundation
import RecognitionFeature
import SwiftUI
import Theme

@Reducer
package struct SelectionFeature {
    @Dependency(NotificationManagerDependency.self) var notificationManager

    package init() {}

    @ObservableState
    package struct State: Equatable {
        package var recognition = RecognitionFeature.State()
        var recognizedStrings: [RecognizedString]?

        package init() {}
    }

    package enum Action {
        case onAppear
        case observeDeviceRotation
        case deviceOrientationDidChange
        case delegate(Delegate)
        case recognition(RecognitionFeature.Action)

        @CasePathable
        package enum Delegate {
            case didDismiss
            case didSelectString(RecognizedString)
        }
    }

    package var body: some ReducerOf<Self> {
        Scope(state: \.recognition, action: \.recognition) {
            RecognitionFeature()
        }

        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    await send(.recognition(.start))
                }
            case .observeDeviceRotation:
                return .run { send in
                    for await _ in await notificationManager.observe(UIDevice.orientationDidChangeNotification) {
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
            case .recognition, .delegate:
                return .none
            }
        }
    }
}

package struct SelectionFeatureView: View {
    package let store: StoreOf<SelectionFeature>
    @Environment(\.colorScheme) var colorScheme

    package init(store: StoreOf<SelectionFeature>) {
        self.store = store
    }

    package var body: some View {
        WithPerceptionTracking {
            ZStack(alignment: .topLeading) {
                RecognitionFeatureView(store: store.scope(state: \.recognition, action: \.recognition))

                ZStack {
                    (colorScheme == .dark ? Color.white : Color.black)
                        .opacity(0.2)
                        .mask {
                            ZStack {
                                Color(.white)
                                highlights(color: .black)
                            }
                            .compositingGroup()
                            .luminanceToAlpha()
                        }

                    highlights(
                        color: .white.opacity(0.001),
                        onSelectString: { store.send(.delegate(.didSelectString($0))) }
                    )
                }
                .ignoresSafeArea()

                Button(action: { store.send(.delegate(.didDismiss)) }) {
                    Image.theme(.close)
                        .padding()
                }
            }
            .onAppear { store.send(.onAppear) }
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
                        .position(x: line.boundingBox.midX, y: UIScreen.main.bounds.height - line.boundingBox.midY)
                        .onTapGesture {
                            onSelectString(recognizedString)
                        }
                }
            }
        }
        .ignoresSafeArea()
    }
}
