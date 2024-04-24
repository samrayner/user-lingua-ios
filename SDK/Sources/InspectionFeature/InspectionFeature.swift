// InspectionFeature.swift

import AsyncAlgorithms
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
    @Dependency(NotificationManagerDependency.self) var notificationManager

    package init() {}

    @ObservableState
    package struct State: Equatable {
        enum Field: String, Hashable {
            case suggestion
        }

        enum PreviewMode: CaseIterable {
            case textual
            case visual

            var icon: Image {
                switch self {
                case .textual:
                    Image.theme(.textualPreviewMode)
                case .visual:
                    Image.theme(.visualPreviewMode)
                }
            }
        }

        package let recognizedString: RecognizedString
        package var appContentSizeCategory: UIContentSizeCategory
        package var darkModeIsEnabled: Bool
        package var recognition = RecognitionFeature.State()
        var configuration: Configuration = .init(baseLocale: Locale(identifier: "en")) // TODO: @Shared
        var focusedField: Field?
        var suggestionString: String
        var localeIdentifier = Locale.current.identifier.replacingOccurrences(of: "_", with: "-")
        var previewMode: PreviewMode = .visual
        var isFullScreen = false
        var keyboardHeight: CGFloat = 0

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
            appContentSizeCategory: UIContentSizeCategory,
            darkModeIsEnabled: Bool
        ) {
            self.recognizedString = recognizedString
            self.appContentSizeCategory = appContentSizeCategory
            self.darkModeIsEnabled = darkModeIsEnabled
            self.suggestionString = recognizedString.value
        }
    }

    package enum Action: BindableAction {
        case didTapSuggestionPreview
        case didTapIncreaseTextSize
        case didTapDecreaseTextSize
        case didTapClose
        case didTapToggleDarkMode
        case didTapToggleFullScreen
        case didTapDoneSuggesting
        case didTapSubmit
        case saveSuggestion
        case viewportFrameDidChange(CGRect, animationDuration: TimeInterval = 0)
        case keyboardWillChangeFrame(CGRect)
        case observeKeyboardWillChangeFrame
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
                state.darkModeIsEnabled.toggle()
                return .none
            case .didTapToggleFullScreen:
                state.focusedField = nil
                state.isFullScreen.toggle()
                return .none
            case .didTapDoneSuggesting:
                state.focusedField = nil
                return .none
            case .didTapSubmit:
                print("SUBMITTED \(state.makeSuggestion())")
                return .none
            case .saveSuggestion:
                suggestionsRepository.saveSuggestion(state.makeSuggestion())
                appViewModel.refresh()
                return .none
            case let .viewportFrameDidChange(frame, animationDuration):
                windowManager.translateApp(
                    focusing: state.recognizedString.boundingBoxCenter,
                    in: frame,
                    animationDuration: animationDuration
                )
                return .none
            case let .keyboardWillChangeFrame(frame):
                let newHeight = max(0, UIScreen.main.bounds.height - frame.origin.y)
                if newHeight != state.keyboardHeight {
                    state.keyboardHeight = newHeight
                }
                return .none
            case .observeKeyboardWillChangeFrame:
                return .run { send in
                    let stream = await notificationManager.observe(name: .swizzled(UIResponder.keyboardWillChangeFrameNotification))
                        .compactMap { KeyboardNotification(userInfo: $0.userInfo) }

                    for await keyboardNotification in stream {
                        await send(
                            .keyboardWillChangeFrame(keyboardNotification.endFrame),
                            animation: keyboardNotification.animation
                        )
                    }
                }
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
    @Environment(\.colorScheme) private var colorScheme
    @Dependency(\.locale) var systemLocale
    @Perception.Bindable package var store: StoreOf<InspectionFeature>
    @FocusState var focusedField: InspectionFeature.State.Field?

    package init(store: StoreOf<InspectionFeature>) {
        self.store = store
    }

    private var ignoredSafeAreaEdges: Edge.Set {
        if store.isFullScreen {
            .all
        } else if store.keyboardHeight > 0 {
            .bottom
        } else {
            []
        }
    }

    package var body: some View {
        WithPerceptionTracking {
            ZStack(alignment: .top) {
                RecognitionFeatureView(store: store.scope(state: \.recognition, action: \.recognition))

                VStack(spacing: 0) {
                    if !store.isFullScreen {
                        header()
                            .transition(.move(edge: .top))
                    }

                    ZStack {
                        Group {
                            if store.previewMode == .visual {
                                visualPreviewControls()
                                    .environment(\.colorScheme, store.darkModeIsEnabled ? .light : .dark)
                            }

                            if store.previewMode == .textual {
                                textualPreview()
                                    .environment(\.colorScheme, colorScheme == .dark ? .light : .dark)
                            }
                        }

                        viewport()
                    }

                    if !store.isFullScreen {
                        inspectionPanel()
                            .transition(.move(edge: .bottom))
                    }
                }
                .ignoresSafeArea(.all, edges: ignoredSafeAreaEdges)
            }
            .font(.theme(.body))
            .task { await store.send(.observeKeyboardWillChangeFrame).finish() }
        }
    }

    @ViewBuilder
    func header() -> some View {
        HStack {
            Button(action: { store.send(.didTapClose) }) {
                Image.theme(.close)
                    .padding(.Space.s)
            }

            Spacer()

            Picker(Strings.Inspection.PreviewModePicker.title, selection: $store.previewMode) {
                ForEach(InspectionFeature.State.PreviewMode.allCases, id: \.self) { previewMode in
                    previewMode.icon
                        .tag(previewMode)
                }
            }
            .pickerStyle(.segmented)
            .fixedSize()
        }
        .padding(.Space.s)
        .background {
            Color.theme(.background)
                .ignoresSafeArea(edges: .top)
        }
    }

    @ViewBuilder
    func textualPreview() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                textualPreviewRow(
                    title: Text(
                        Strings.Inspection.TextualPreview.baseTitle(
                            systemLocale.localizedString(forLanguageCode: store.configuration.baseLocale.identifier)
                                ?? Strings.Inspection.TextualPreview.languageNameFallback,
                            store.configuration.baseLocale.identifier
                        )
                    ),
                    string: Text(localizedValueWithHighlightedPlaceholders(locale: store.configuration.baseLocale))
                )

                if store.localeIdentifier != store.configuration.baseLocale.identifier {
                    HorizontalRule()

                    textualPreviewRow(
                        title: Text(
                            Strings.Inspection.TextualPreview.originalTitle(
                                systemLocale.localizedString(forLanguageCode: store.localeIdentifier)
                                    ?? Strings.Inspection.TextualPreview.languageNameFallback,
                                store.localeIdentifier
                            )
                        ),
                        string: Text(localizedValueWithHighlightedPlaceholders(locale: store.locale))
                    )
                }

                HorizontalRule()

                textualPreviewRow(
                    title: Text(
                        Strings.Inspection.TextualPreview.suggestionTitle(
                            systemLocale.localizedString(forLanguageCode: store.localeIdentifier)
                                ?? store.localeIdentifier,
                            store.localeIdentifier
                        )
                    ),
                    string: Text(store.suggestionString)
                )
            }
        }
        .background(Color.theme(.background))
    }

    @ViewBuilder
    private func visualPreviewControls() -> some View {
        VStack {
            Spacer()

            HStack(spacing: 0) {
                Button(action: { store.send(.didTapDecreaseTextSize) }) {
                    Image.theme(.decreaseTextSize)
                        .padding(.Space.s)
                        .padding(.leading, .Space.s)
                }

                Button(action: { store.send(.didTapIncreaseTextSize) }) {
                    Image.theme(.increaseTextSize)
                        .padding(.Space.s)
                }

                Button(action: {
                    store.send(.didTapToggleDarkMode)
                }) {
                    Image.theme(store.darkModeIsEnabled ? .untoggleDarkMode : .toggleDarkMode)
                        .padding(.Space.s)
                }

                Button(action: { store.send(.didTapToggleFullScreen, animation: .easeOut) }) {
                    Image.theme(store.isFullScreen ? .exitFullScreen : .enterFullScreen)
                        .padding(.Space.s)
                        .padding(.trailing, .Space.s)
                }
            }
            .background {
                Color.theme(.background)
                    .opacity(.Opacity.heavy)
                    .cornerRadius(.infinity)
            }
            .padding(.Space.m)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    @ViewBuilder
    private func viewport() -> some View {
        RoundedRectangle(cornerRadius: .Radius.l)
            .inset(by: -.BorderWidth.xl)
            .strokeBorder(Color.theme(.background), lineWidth: .BorderWidth.xl)
            .padding(.horizontal, store.isFullScreen ? 0 : .Space.xs)
            .ignoresSafeArea(.all)
            .background {
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            store.send(.viewportFrameDidChange(geometry.frame(in: .global)))
                        }
                        .onChange(of: geometry.frame(in: .global)) {
                            store.send(.viewportFrameDidChange($0, animationDuration: .AnimationDuration.quick))
                        }
                }
            }
    }

    @ViewBuilder
    private func textualPreviewRow(title: Text, string: Text) -> some View {
        VStack(alignment: .leading, spacing: .Space.s) {
            title
                .font(.theme(.textualPreviewHeading))
                .frame(maxWidth: .infinity, alignment: .leading)

            string
                .font(.theme(.textualPreviewString))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.Space.l)
    }

    @ViewBuilder
    private func inspectionPanel() -> some View {
        VStack(alignment: .leading, spacing: .Space.m) {
            HStack(spacing: .Space.m) {
                TextField(Strings.Inspection.SuggestionField.placeholder, text: $store.suggestionString, axis: .vertical)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($focusedField, equals: .suggestion)
                    .frame(maxWidth: .infinity, minHeight: 30)
                    .overlay(alignment: .leading) {
                        if focusedField != .suggestion && store.suggestionString == store.localizedValue {
                            Text(
                                store.recognizedString.localizedValue(
                                    locale: store.locale,
                                    placeholderAttributes: [
                                        .backgroundColor: UIColor.theme(.placeholderBackground),
                                        .foregroundColor: UIColor.theme(.placeholderText)
                                    ],
                                    placeholderTransform: { " \($0) " }
                                )
                            )
                            .background(Color.theme(.suggestionFieldBackground))
                            .onTapGesture { store.send(.didTapSuggestionPreview) }
                        }
                    }
                    .padding(.Space.s)
                    .background(Color.theme(.suggestionFieldBackground))
                    .cornerRadius(.Radius.m)

                if focusedField == .suggestion {
                    Button(action: { store.send(.didTapDoneSuggesting) }) {
                        Image.theme(.doneSuggesting)
                    }
                }
            }

            VStack(alignment: .leading, spacing: .Space.m) {
                if store.recognizedString.isLocalized {
                    LocalePickerView(selectedIdentifier: $store.localeIdentifier)
                }

                if let localization = store.recognizedString.localization {
                    VStack(alignment: .leading, spacing: 1) {
                        localizationDetailsRow(
                            Text("\(Strings.Inspection.Localization.Key.title): ").bold() +
                                Text(localization.key)
                        )

                        localizationDetailsRow(
                            Text("\(Strings.Inspection.Localization.Table.title): ").bold() +
                                Text("\(localization.tableName ?? "Localizable").strings")
                        )

                        if let comment = localization.comment {
                            localizationDetailsRow(
                                Text("\(Strings.Inspection.Localization.Comment.title): ").bold() +
                                    Text(comment)
                            )
                        }
                    }
                    .cornerRadius(.Radius.m)
                }

                if store.suggestionString != store.localizedValue {
                    Button(action: { store.send(.didTapSubmit) }) {
                        Text(Strings.Inspection.submitButton)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.primary)
                }
            }
            .frame(minHeight: store.keyboardHeight)
        }
        .padding(.top, .Space.m)
        .padding(.bottom, .Space.s)
        .padding(.horizontal, .Space.m)
        .background(Color.theme(.background))
        .bind($store.focusedField, to: $focusedField)
    }

    @ViewBuilder
    private func localizationDetailsRow(_ content: some View) -> some View {
        content
            .padding(.Space.s)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.theme(.localizationDetailsBackground))
    }

    private func localizedValueWithHighlightedPlaceholders(locale: Locale) -> AttributedString {
        store.recognizedString.localizedValue(
            locale: locale,
            placeholderAttributes: [
                .backgroundColor: UIColor.theme(.placeholderBackground),
                .foregroundColor: UIColor.theme(.placeholderText)
            ],
            placeholderTransform: { " \($0) " }
        )
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
