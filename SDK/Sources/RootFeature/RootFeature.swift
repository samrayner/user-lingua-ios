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

        package init() {}
    }

    package enum Action {
        case disable
        case enable
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
                state.mode = .selection(.init())
                onForeground()
                return .none
            case .mode(.inspection(.delegate(.didDismiss))):
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
            case let .mode(.selection(.delegate(.didSelectString(recognizedString)))):
                ThemeFont.scaleFactor = contentSizeCategoryManager.systemPreferredContentSizeCategory.fontScaleFactor
                state.mode = .inspection(
                    .init(
                        recognizedString: recognizedString,
                        appContentSizeCategory: contentSizeCategoryManager.systemPreferredContentSizeCategory,
                        darkModeIsEnabled: windowManager.appUIStyle == .dark,
                        appFacade: windowManager.screenshotAppWindow()
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
    @Dependency(WindowManagerDependency.self) var windowManager

    let store: StoreOf<RootFeature>

    private var invertedColorSchene: ColorScheme {
        windowManager.appUIStyle == .light ? .dark : .light
    }

    package init(store: StoreOf<RootFeature>) {
        self.store = store
    }

    package var body: some View {
        WithPerceptionTracking {
            ZStack {
                if let selectionStore = store.scope(state: \.mode.selection, action: \.mode.selection) {
                    SelectionFeatureView(store: selectionStore)
                } else {
                    // retain ColorScheme for InspectionFeatureView during transitions
                    Color.clear.preferredColorScheme(invertedColorSchene)
                }

                Group {
                    if let inspectionStore = store.scope(state: \.mode.inspection, action: \.mode.inspection) {
                        InspectionFeatureView(store: inspectionStore)
                            .foregroundColor(.theme(\.text))
                            .tint(.theme(\.tint))
                            .preferredColorScheme(invertedColorSchene)
                            .transition(.move(edge: .bottom))
                    }
                }
                .animation(.snappy, value: store.mode) // animate the transition in/out
            }
        }
    }
}
