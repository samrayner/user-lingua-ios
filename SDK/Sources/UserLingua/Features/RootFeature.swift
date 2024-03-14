// RootFeature.swift

import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
struct RootFeature {
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
        case didDisable
        case didEnable
        case didShake
        case didConfigure(UserLinguaConfiguration)
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
            case .didEnable:
                swizzle()
                UserLingua.shared.startObservingShake() // TODO: use Dependency instead of singleton
                state.mode = .recording
                return .none
            case .didDisable:
                unswizzle()
                UserLingua.shared.stopObservingShake() // TODO: use Dependency instead of singleton
                state.mode = .disabled
                return .none
            case .didShake:
                state.mode = .selection(.init())
                return .none
            case let .didConfigure(configuration):
                state.configuration = configuration
                return .none
            case .mode(.selection(.delegate(.didHide))):
                state.mode = .disabled
                return .none
            case let .mode(.selection(.delegate(.didSelectString(recordedString)))):
                state.mode = .inspection(.init(recordedString: recordedString))
                return .none
            case .mode:
                return .none
            }
        }
    }

    private func swizzle() {
        Bundle.swizzle()
        UILabel.swizzle()
        UIButton.swizzle()
    }

    private func unswizzle() {
        Bundle.unswizzle()
        UILabel.unswizzle()
        UIButton.unswizzle()
    }
}

struct RootFeatureView: View {
    @Perception.Bindable var store: StoreOf<RootFeature>

    var body: some View {
        WithPerceptionTracking {
            if let store = store.scope(state: \.mode.selection, action: \.mode.selection) {
                SelectionFeatureView(store: store)
            } else if let store = store.scope(state: \.mode.inspection, action: \.mode.inspection) {
                VStack {
                    Spacer()
                    InspectionFeatureView(store: store)
                }
            } else {
                EmptyView()
            }
        }
    }
}
