// RootFeature.swift

import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
struct RootFeature {
    @Dependency(WindowManagerDependency.self) var windowManager
    @Dependency(TriggerObserverDependency.self) var triggerObserver
    @Dependency(SwizzlerDependency.self) var swizzler

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
        case interfaceDidAppear(any View)
        case interfaceDidDisappear
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
                state.mode = .selection(.init())
                return .none
            case .mode(.selection(.delegate(.didDismiss))),
                 .mode(.inspection(.delegate(.didDismiss))):
                state.mode = .recording
                return .none
            case let .mode(.selection(.delegate(.didSelectString(recordedString)))):
                state.mode = .inspection(.init(recordedString: recordedString))
                return .none
            case .mode:
                return .none
            case let .interfaceDidAppear(view):
                windowManager.showWindow(rootView: view)
                return .none
            case .interfaceDidDisappear:
                windowManager.hideWindow()
                return .none
            }
        }
    }
}

struct RootFeatureView: View {
    @Perception.Bindable var store: StoreOf<RootFeature>

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
                        }
                    }
                }
                .onAppear { store.send(.interfaceDidAppear(self)) }
                .onDisappear { store.send(.interfaceDidDisappear) }
            }
        }
    }
}
