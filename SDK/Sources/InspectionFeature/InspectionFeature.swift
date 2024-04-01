// InspectionFeature.swift

import ComposableArchitecture
import Core
import Foundation
import RecognitionFeature
import SFSafeSymbols
import SwiftUI

public typealias StackActionOf<R: Reducer> = StackAction<R.State, R.Action>

@Reducer
package struct InspectionFeature {
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(SuggestionsRepositoryDependency.self) var suggestionsRepository
    @Dependency(UserLinguaObservableDependency.self) var appViewModel

    package init() {}

    // https://github.com/pointfreeco/swift-composable-architecture/discussions/2936
    @Reducer(state: .equatable)
    public enum Path {
        // case other(OtherFeature)
    }

    @ObservableState
    package struct State: Equatable {
        package let recordedString: RecordedString
        package var recognition = RecognitionFeature.State()
        var suggestionString: String
        var localeIdentifier = Locale.current.identifier.replacingOccurrences(of: "_", with: "-")
        var path = StackState<Path.State>()

        package var locale: Locale {
            Locale(identifier: localeIdentifier)
        }

        package init(recordedString: RecordedString) {
            self.recordedString = recordedString
            self.suggestionString = recordedString.value
        }
    }

    package enum Action: BindableAction {
        case saveSuggestion
        case binding(BindingAction<State>)
        case delegate(Delegate)
        case path(StackActionOf<Path>)
        case recognition(RecognitionFeature.Action)

        @CasePathable
        package enum Delegate {
            case didDismiss
        }
    }

    enum CancelID {
        case suggestionSaveDebounce
    }

    package var body: some ReducerOf<Self> {
        BindingReducer()

        Scope(state: \.recognition, action: \.recognition) {
            RecognitionFeature()
        }

        Reduce { state, action in
            switch action {
            case .saveSuggestion:
                suggestionsRepository.saveSuggestion(
                    .init(
                        recordedString: state.recordedString,
                        newValue: state.suggestionString,
                        locale: state.locale
                    )
                )
                appViewModel.refresh()
                return .none
            case .binding(\.localeIdentifier):
                state.suggestionString = suggestionsRepository.suggestion(
                    recorded: state.recordedString,
                    locale: state.locale
                )?.newValue ?? state.recordedString.localizedValue(locale: state.locale)
                appViewModel.refresh()
                return .none
            case .binding(\.suggestionString):
                return .run { send in
                    await send(.saveSuggestion)
                }
                // debounce primarily to avoid SwiftUI bug:
                // https://github.com/pointfreeco/swift-composable-architecture/discussions/1093
                .debounce(id: CancelID.suggestionSaveDebounce, for: .seconds(0.1), scheduler: mainQueue)
            case .delegate(.didDismiss):
                appViewModel.refresh()
                return .none
            case .recognition, .binding, .delegate, .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

package struct InspectionFeatureView: View {
    @Perception.Bindable package var store: StoreOf<InspectionFeature>

    package init(store: StoreOf<InspectionFeature>) {
        self.store = store
    }

    package var body: some View {
        WithPerceptionTracking {
            ZStack {
                RecognitionFeatureView(store: store.scope(state: \.recognition, action: \.recognition))

                NavigationStack(
                    path: $store.scope(state: \.path, action: \.path)
                ) {
                    Form {
                        Picker("Language", selection: $store.localeIdentifier) {
                            ForEach(Bundle.main.preferredLocalizations, id: \.self) { identifier in
                                Text(Locale.current.localizedString(forIdentifier: identifier) ?? identifier)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(height: 50)

                        Section("Original") {
                            Text(
                                store.recordedString.localizedValue(
                                    locale: store.locale,
                                    placeholderAttributes: [.backgroundColor: UIColor.cyan]
                                )
                            )
                        }

                        Section("Suggestion") {
                            TextField("Suggestion", text: $store.suggestionString)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }

                        if let localization = store.recordedString.localization {
                            Section("Localization") {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text("Key:")
                                        Text(localization.key)
                                    }

                                    HStack {
                                        Text("Table:")
                                        Text(localization.tableName ?? "Localizable")
                                    }

                                    HStack {
                                        Text("Comment:")
                                        Text(localization.comment ?? "[None]")
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("UserLingua")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem {
                            Button(action: { store.send(.delegate(.didDismiss)) }) {
                                Image(systemSymbol: .xmarkCircleFill)
                            }
                        }
                    }
                } destination: { _ in
                    EmptyView()
                    //                switch store.case {
                    //                case let .other(store):
                    //                    OtherFeatureView(store: store)
                    //                }
                }
            }
        }
    }
}

// #Preview {
//    InspectionFeatureView(
//        store: Store(
//            initialState: InspectionFeature.State(
//                recordedString: .init("Preview")
//            ),
//            reducer: {
//                InspectionFeature()
//                    ._printChanges()
//            }
//        )
//    )
// }