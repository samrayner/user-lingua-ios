// RootFeature.swift

import ComposableArchitecture
import Core
import Foundation
import InspectionFeature
import RecognitionFeature
import SelectionFeature
import SwiftUI

@Reducer
package struct RootFeature {
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

    // https://github.com/pointfreeco/swift-composable-architecture/discussions/2936
    @Reducer(state: .equatable)
    public enum Mode {
        case disabled
        case recording
        case selection(SelectionFeature)
        case inspection(InspectionFeature)
    }

    @ObservableState
    package struct State: Equatable {
        package var configuration: Configuration = .init()
        package var mode: Mode.State = .disabled
        package var keyboardPadding: CGFloat = 0

        package init() {}
    }

    package enum Action {
        case disable
        case enable
        case configure(Configuration)
        case didShake
        case keyboardWillChangeFrame(CGRect)
        case observeKeyboardWillChangeFrame
        case mode(Mode.Action)
    }

    enum CancelID {
        case deviceShakeObservation
    }

    package var body: some ReducerOf<Self> {
        Scope(state: \.mode, action: \.mode) {
            EmptyReducer()
                .ifCaseLet(\.selection, action: \.selection) {
                    SelectionFeature()
                }
                .ifCaseLet(\.inspection, action: \.inspection) {
                    InspectionFeature()
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
                state.keyboardPadding = 0
                state.mode = .selection(.init())
                onForeground()
                return .none
            case .mode(.selection(.delegate(.didDismiss))),
                 .mode(.inspection(.delegate(.didDismiss))):
                state.mode = .recording
                contentSizeCategoryManager.notifyDidChange(newValue: contentSizeCategoryManager.systemPreferredContentSizeCategory)
                appViewModel.refresh()
                windowManager.hideWindow()
                onBackground()
                return .none
            case let .keyboardWillChangeFrame(frame):
                // For some reason the keyboard height is always
                // reported as 75pts when it should be 0.
                state.keyboardPadding = frame.height <= 100 ? 0 : frame.height
                return .none
            case .observeKeyboardWillChangeFrame:
                let keyboardNotificationNames: [Notification.Name] = [
                    .swizzled(UIResponder.keyboardWillChangeFrameNotification),
                    .swizzled(UIResponder.keyboardWillHideNotification),
                    .swizzled(UIResponder.keyboardWillShowNotification)
                ]

                return .run { send in
                    for await notification in await notificationManager.observe(names: keyboardNotificationNames) {
                        if let keyboardNotification = KeyboardNotification(userInfo: notification.userInfo) {
                            await send(
                                .keyboardWillChangeFrame(keyboardNotification.endFrame),
                                animation: keyboardNotification.animation
                            )
                        }
                    }
                }
            case let .mode(.selection(.delegate(.didSelectString(recognizedString)))):
                state.mode = .inspection(
                    .init(
                        recognizedString: recognizedString,
                        appContentSizeCategory: contentSizeCategoryManager.systemPreferredContentSizeCategory
                    )
                )
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
            Group {
                switch store.mode {
                case .disabled, .recording:
                    EmptyView()
                case .selection, .inspection:
                    ZStack {
                        if let store = store.scope(state: \.mode.selection, action: \.mode.selection) {
                            SelectionFeatureView(store: store)
                        } else if let store = store.scope(state: \.mode.inspection, action: \.mode.inspection) {
                            InspectionFeatureView(store: store)
                        }
                    }
                }
            }
            .padding(.bottom, store.keyboardPadding)
            .ignoresSafeArea(.all, edges: .bottom)
            .foregroundColor(.theme(.text))
            .tint(.theme(.tint))
            .task { await store.send(.observeKeyboardWillChangeFrame).finish() }
        }
    }
}
