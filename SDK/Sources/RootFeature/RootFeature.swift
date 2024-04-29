// RootFeature.swift

import ComposableArchitecture
import Core
import Foundation
import InspectionFeature
import RecognitionFeature
import SelectionFeature
import SwiftUI
import Theme

@Reducer
package struct RootFeature {
    @Dependency(\.continuousClock) var clock
    @Dependency(WindowManagerDependency.self) var windowManager
    @Dependency(UserLinguaObservableDependency.self) var appViewModel
    @Dependency(NotificationManagerDependency.self) var notificationManager
    @Dependency(ContentSizeCategoryManagerDependency.self) var contentSizeCategoryManager

    let onForeground: () -> Void
    let onBackground: () -> Void

    package init(
        onForeground: @escaping () -> Void = {},
        onBackground: @escaping () -> Void = {}
    ) {
        self.onForeground = onForeground
        self.onBackground = onBackground
    }

    @Reducer(state: .equatable)
    package enum Mode {
        case disabled
        case recording
        case visible(SelectionFeature)
    }

    @ObservableState
    package struct State: Equatable {
        package var configuration: Configuration = .init()
        package var mode: Mode.State = .disabled

        package init() {}
    }

    package enum Action {
        case enable
        case disable
        case configure(Configuration)
        case didShake
        case backgroundTransitionDidComplete
        case mode(Mode.Action)
    }

    enum CancelID {
        case deviceShakeObservation
    }

    package var body: some ReducerOf<Self> {
        Scope(state: \.mode, action: \.mode) {
            EmptyReducer()
                .ifCaseLet(\.visible, action: \.visible) {
                    SelectionFeature()
                }
        }

        Reduce { state, action in
            switch action {
            case .enable:
                state.mode = .recording
                return .run { send in
                    for await _ in await notificationManager.observe(name: .deviceDidShake) {
                        await send(.didShake)
                    }
                }
                .cancellable(id: CancelID.deviceShakeObservation)
            case .disable:
                state.mode = .disabled
                return .cancel(id: CancelID.deviceShakeObservation)
            case let .configure(configuration):
                state.configuration = configuration
                return .none
            case .didShake:
                guard state.mode == .recording else { return .none }
                windowManager.showWindow()
                state.mode = .visible(.init())
                onForeground()
                return .none
            case .mode(.visible(.delegate(.inspectionDidDismiss))):
                contentSizeCategoryManager.notifyDidChange(newValue: contentSizeCategoryManager.systemPreferredContentSizeCategory)
                windowManager.resetAppWindow()
                state.mode = .recording
                appViewModel.refresh()
                onBackground()
                return .run { send in
                    // withAnimation(completion:) is iOS 17+ only
                    try await clock.sleep(for: .seconds(.AnimationDuration.screenTransition))
                    await send(.backgroundTransitionDidComplete)
                }
            case .backgroundTransitionDidComplete:
                windowManager.hideWindow()
                return .none
            case .mode:
                return .none
            }
        }
    }
}

package struct RootFeatureView: View {
    let store: StoreOf<RootFeature>

    package init(store: StoreOf<RootFeature>) {
        self.store = store
    }

    package var body: some View {
        WithPerceptionTracking {
            ZStack {
                if let store = store.scope(state: \.mode.visible, action: \.mode.visible) {
                    SelectionFeatureView(store: store)
                }
            }
            .foregroundColor(.theme(\.text))
            .tint(.theme(\.tint))
        }
    }
}
