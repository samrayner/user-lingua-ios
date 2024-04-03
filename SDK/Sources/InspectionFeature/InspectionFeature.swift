// InspectionFeature.swift

import ComposableArchitecture
import Core
import Foundation
import RecognitionFeature
import Strings
import SwiftUI
import Theme

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
        enum Field: String, Hashable {
            case suggestion
        }

        package let recognizedString: RecognizedString
        package var recognition = RecognitionFeature.State()
        var focusedField: Field?
        var suggestionString: String
        var localeIdentifier = Locale.current.identifier.replacingOccurrences(of: "_", with: "-")
        var path = StackState<Path.State>()

        package var locale: Locale {
            Locale(identifier: localeIdentifier)
        }

        var localizedValue: String {
            recognizedString.localizedValue(locale: locale)
        }

        func makeSuggestion() -> Suggestion {
            .init(
                recordedString: recognizedString.recordedString,
                newValue: suggestionString,
                locale: locale
            )
        }

        package init(recognizedString: RecognizedString) {
            self.recognizedString = recognizedString
            self.suggestionString = recognizedString.value
        }
    }

    package enum Action: BindableAction {
        case saveSuggestion
        case didTapSuggestionPreview
        case binding(BindingAction<State>)
        case delegate(Delegate)
        case path(StackAction<Path.State, Path.Action>) // TODO: StackActionOf<Path>
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
                suggestionsRepository.saveSuggestion(state.makeSuggestion())
                appViewModel.refresh()
                return .none
            case .didTapSuggestionPreview:
                state.focusedField = .suggestion
                return .none
            case .binding(\.localeIdentifier):
                state.suggestionString = suggestionsRepository.suggestion(
                    for: state.recognizedString.value,
                    locale: state.locale
                )?.newValue ?? state.localizedValue
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
    @FocusState var focusedField: InspectionFeature.State.Field?

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
                    VStack {
                        Picker(Strings.Inspection.LanguagePicker.title, selection: $store.localeIdentifier) {
                            ForEach(Bundle.main.preferredLocalizations, id: \.self) { identifier in
                                Text(Locale.current.localizedString(forIdentifier: identifier) ?? identifier)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(height: 50)

                        ZStack(alignment: .topLeading) {
                            TextField(Strings.Inspection.SuggestionField.placeholder, text: $store.suggestionString, axis: .vertical)
                                .focused($focusedField, equals: .suggestion)
                                .textFieldStyle(.plain)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .background(Color.theme(.suggestionFieldBackground))

                            if focusedField != .suggestion && store.suggestionString == store.localizedValue {
                                Text(
                                    store.recognizedString.localizedValue(
                                        locale: store.locale,
                                        placeholderAttributes: [.backgroundColor: UIColor.theme(.placeholderHighlight)],
                                        placeholderTransform: { " \($0) " }
                                    )
                                )
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                .background(Color.theme(.suggestionFieldBackground))
                                .onTapGesture { store.send(.didTapSuggestionPreview) }
                            }
                        }
                        .border(Color.theme(.suggestionFieldBorder), cornerRadius: 3)

                        if let localization = store.recognizedString.localization {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("\(Strings.Inspection.Localization.Key.title):")
                                    Text(localization.key)
                                }

                                HStack {
                                    Text("\(Strings.Inspection.Localization.Table.title):")
                                    Text(localization.tableName ?? "Localizable")
                                }

                                HStack {
                                    Text("\(Strings.Inspection.Localization.Comment.title):")
                                    Text(localization.comment ?? Strings.Inspection.Localization.Comment.none)
                                }
                            }
                        }
                    }
                    .padding()
                    .bind($store.focusedField, to: $focusedField)
                    .navigationTitle(Strings.sdkName)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem {
                            Button(action: { store.send(.delegate(.didDismiss)) }) {
                                Image.theme(.close)
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
                .background(Color.theme(.background))
            }
        }
    }
}

#Preview {
    InspectionFeatureView(
        store: Store(
            initialState: InspectionFeature.State(
                recognizedString: .init(
                    recordedString: .init("Hello"),
                    lines: []
                )
            ),
            reducer: {
                InspectionFeature()
            }
        )
    )
}
