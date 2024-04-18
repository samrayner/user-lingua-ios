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
    @Dependency(ContentSizeCategoryManagerDependency.self) var contentSizeCategoryManager
    @Dependency(WindowManagerDependency.self) var windowManager

    package init() {}

    @ObservableState
    package struct State: Equatable {
        enum Field: String, Hashable {
            case suggestion
        }

        package let recognizedString: RecognizedString
        package var inspectorContentSizeCategory: UIContentSizeCategory
        package var appContentSizeCategory: UIContentSizeCategory
        package var recognition = RecognitionFeature.State()
        var focusedField: Field?
        var suggestionString: String
        var localeIdentifier = Locale.current.identifier.replacingOccurrences(of: "_", with: "-")

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

        package init(
            recognizedString: RecognizedString,
            appContentSizeCategory: UIContentSizeCategory
        ) {
            self.recognizedString = recognizedString
            self.appContentSizeCategory = appContentSizeCategory
            self.inspectorContentSizeCategory = appContentSizeCategory
            self.suggestionString = recognizedString.value
        }
    }

    package enum Action: BindableAction {
        case saveSuggestion
        case didTapSuggestionPreview
        case didTapIncreaseTextSize
        case didTapDecreaseTextSize
        case didTapClose
        case didTapToggleDarkMode
        case binding(BindingAction<State>)
        case delegate(Delegate)
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
            case .didTapIncreaseTextSize:
                state.appContentSizeCategory = state.appContentSizeCategory.incremented()
                contentSizeCategoryManager.notifyDidChange(newValue: state.appContentSizeCategory)
                return .none
            case .didTapDecreaseTextSize:
                state.appContentSizeCategory = state.appContentSizeCategory.decremented()
                contentSizeCategoryManager.notifyDidChange(newValue: state.appContentSizeCategory)
                return .none
            case .didTapClose:
                return .run { send in
                    await send(.delegate(.didDismiss))
                }
            case .didTapToggleDarkMode:
                windowManager.toggleDarkMode()
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
            case .recognition, .binding, .delegate:
                return .none
            }
        }
    }
}

package struct InspectionFeatureView: View {
    @Perception.Bindable package var store: StoreOf<InspectionFeature>
    @FocusState var focusedField: InspectionFeature.State.Field?
    @State private var darkModeIsToggled = false

    package init(store: StoreOf<InspectionFeature>) {
        self.store = store
    }

    package var body: some View {
        WithPerceptionTracking {
            ZStack {
                RecognitionFeatureView(store: store.scope(state: \.recognition, action: \.recognition))

                VStack(spacing: 0) {
                    HStack {
                        Button(action: { store.send(.didTapClose) }) {
                            Image.theme(.close)
                        }

                        Spacer()

                        Button(action: {
                            darkModeIsToggled.toggle()
                            store.send(.didTapToggleDarkMode)
                        }) {
                            Image.theme(darkModeIsToggled ? .untoggleDarkMode : .toggleDarkMode)
                        }

                        Button(action: { store.send(.didTapIncreaseTextSize) }) {
                            Image.theme(.increaseTextSize)
                        }

                        Button(action: { store.send(.didTapDecreaseTextSize) }) {
                            Image.theme(.decreaseTextSize)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.theme(.background))

                    Color.theme(.background)
                        .mask {
                            ZStack {
                                Color.white
                                RoundedRectangle(cornerRadius: .Radius.s)
                                    .fill(Color.black)
                            }
                            .compositingGroup()
                            .luminanceToAlpha()
                        }

                    VStack {
                        ZStack(alignment: .topLeading) {
                            TextField(Strings.Inspection.SuggestionField.placeholder, text: $store.suggestionString, axis: .vertical)
                                .focused($focusedField, equals: .suggestion)
                                .textFieldStyle(.plain)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .background(Color.theme(.suggestionFieldBackground))
                                .overlay(alignment: .leading) {
                                    if focusedField != .suggestion && store.suggestionString == store.localizedValue {
                                        Text(
                                            store.recognizedString.localizedValue(
                                                locale: store.locale,
                                                placeholderAttributes: [.backgroundColor: UIColor.theme(.placeholderHighlight)],
                                                placeholderTransform: { " \($0) " }
                                            )
                                        )
                                        .background(Color.theme(.suggestionFieldBackground))
                                        .onTapGesture { store.send(.didTapSuggestionPreview) }
                                    }
                                }
                        }
                        .border(Color.theme(.suggestionFieldBorder), cornerRadius: 3)

                        Picker(Strings.Inspection.LanguagePicker.title, selection: $store.localeIdentifier) {
                            ForEach(Bundle.main.preferredLocalizations, id: \.self) { identifier in
                                Text(Locale.current.localizedString(forIdentifier: identifier) ?? identifier)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(height: 50)

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
                    .background(Color.theme(.background))
                }
            }
            // we fix the font size for the inspection panel so that we can
            // adjust the DynamicType size for the app preview without
            // affecting the panel.
            .font(.system(size: store.inspectorContentSizeCategory.fixedFontSize))
            .bind($store.focusedField, to: $focusedField)
        }
    }
}

// #Preview {
//    InspectionFeatureView(
//        store: Store(
//            initialState: InspectionFeature.State(
//                recognizedString: .init(
//                    recordedString: .init("Hello"),
//                    lines: []
//                )
//            ),
//            reducer: {
//                InspectionFeature()
//            }
//        )
//    )
// }
