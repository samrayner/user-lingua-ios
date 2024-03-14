// InspectionFeature.swift

import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
struct InspectionFeature {
    @Reducer(state: .equatable)
    enum Path {
        // case other(OtherFeature)
    }

    @ObservableState
    struct State: Equatable {
        let recordedString: RecordedString
        var locale = Locale.current
        var path = StackState<Path.State>()
    }

    enum Action {
        case didSetLocale(Locale)
        case path(StackAction<Path.State, Path.Action>) // StackActionOf<Path> in TCA 1.9
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .didSetLocale(locale):
                state.locale = locale
                return .none
            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

struct InspectionFeatureView: View {
    @Perception.Bindable var store: StoreOf<InspectionFeature>

    var body: some View {
        NavigationStack(
            path: $store.scope(state: \.path, action: \.path)
        ) {
            Form {
                Section {
                    Text("Inspector")
                }
            }
            .navigationTitle("Inspector")
        } destination: { _ in
//            switch store.case {
//            case let .other(store):
//                OtherFeatureView(store: store)
//            }
        }
    }
}
