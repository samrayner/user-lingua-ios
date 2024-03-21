// RootFeature.swift

import ComposableArchitecture
import Core
import Foundation
import InspectionFeature
import SelectionFeature
import SwiftUI

@Reducer
package struct RootFeature {
    @Dependency(WindowManagerDependency.self) var windowManager

    package init() {}

    // TODO: https://github.com/pointfreeco/swift-composable-architecture/discussions/2936
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
        case mode(Mode.Action)
    }

    package var body: some ReducerOf<Self> {
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
                state.mode = .recording
                return .none
            case .disable:
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

package struct RootFeatureView: View {
    let store: StoreOf<RootFeature>

    package init(store: StoreOf<RootFeature>) {
        self.store = store
    }

    package var body: some View {
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
