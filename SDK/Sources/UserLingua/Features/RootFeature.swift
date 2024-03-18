// RootFeature.swift

import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
struct RootFeature {
    @Dependency(TriggerObserverDependency.self) var triggerObserver
    @Dependency(SwizzlerDependency.self) var swizzler
    @Dependency(WindowManagerDependency.self) var windowManager

    @Reducer(state: .equatable)
    enum Mode {
        case disabled
        case recording
        case selection(SelectionFeature)
        case inspection(InspectionFeature)
    }

    @ObservableState
    struct State: Equatable {
        var configuration: UserLinguaConfiguration = .init()
        var mode: Mode.State = .disabled

        var locale: Locale {
            if case let .inspection(state) = mode {
                state.locale
            } else {
                .current
            }
        }
    }

    enum Action {
        case disable
        case enable
        case configure(UserLinguaConfiguration)
        case didShake
        case mode(Mode.Action)
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.mode, action: \.mode) {
            EmptyReducer()
                .ifCaseLet(\.selection, action: \.selection) {
                    SelectionFeature()
                }
                .ifCaseLet(\.inspection, action: \.inspection) {
                    InspectionFeature()
                        ._printChanges()
                }
        }

        Reduce { state, action in
            switch action {
            case .enable:
                swizzler.swizzle()
                triggerObserver.startObservingShake()
                state.mode = .recording
                return .none
            case .disable:
                swizzler.unswizzle()
                triggerObserver.stopObservingShake()
                state.mode = .disabled
                return .none
            case let .configure(configuration):
                state.configuration = configuration
                return .none
            case .didShake:
                windowManager.showWindow()
                state.mode = .selection(.init())
                return .none
            case .mode(.selection(.delegate(.didDismiss))),
                 .mode(.inspection(.delegate(.didDismiss))):
                state.mode = .recording
                windowManager.hideWindow()
                return .none
            case let .mode(.selection(.delegate(.didSelectString(recordedString)))):
                state.mode = .inspection(.init(recordedString: recordedString))
                return .none
            case .mode:
                return .none
            }
        }
    }
}

struct RootFeatureView: View {
    let store: StoreOf<RootFeature>

    var body: some View {
        WithPerceptionTracking {
            switch store.mode {
            case .disabled, .recording:
                EmptyView()
            case .selection, .inspection:
                Group {
                    if let store = store.scope(state: \.mode.selection, action: \.mode.selection) {
                        SelectionFeatureView(store: store)
                    } else if let store = store.scope(state: \.mode.inspection, action: \.mode.inspection) {
                        VStack {
                            Spacer()
                            InspectionFeatureView(store: store)
                                .frame(height: 250)
                        }
                    }
                }
            }
        }
    }
}
