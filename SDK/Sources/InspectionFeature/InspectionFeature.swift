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
    @Dependency(\.continuousClock) var clock
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.dismiss) var dismiss
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
                    Image.theme(\.textualPreviewMode)
                case .visual:
                    Image.theme(\.visualPreviewMode)
                }
            }
        }

        package let recognizedString: RecognizedString
        package var darkModeIsEnabled: Bool
        package var isTransitioning = true
        @Shared(RecognitionFeature.State.persistenceKey) var recognition = .init()
        @Shared(Configuration.persistenceKey) var configuration = .init()
        var focusedField: Field?
        var suggestionString: String
        var localeIdentifier = Locale.current.identifier.replacingOccurrences(of: "_", with: "-")
        var previewMode: PreviewMode = .visual
        var isFullScreen = false
        var keyboardHeight: CGFloat = 0
        var appFacade: UIImage?

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
            darkModeIsEnabled: Bool,
            appFacade: UIImage?
        ) {
            self.recognizedString = recognizedString
            self.darkModeIsEnabled = darkModeIsEnabled
            self.appFacade = appFacade
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
        case onAppear
        case didAppear
        case saveSuggestion
        case viewportFrameDidChange(CGRect, animationDuration: TimeInterval = 0)
        case keyboardWillChangeFrame(KeyboardNotification)
        case observeKeyboardWillChangeFrame
        case binding(BindingAction<State>)
        case recognition(RecognitionFeature.Action)
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
                contentSizeCategoryManager.incrementAppContentSizeCategory()
                return .none
            case .didTapDecreaseTextSize:
                contentSizeCategoryManager.decrementAppContentSizeCategory()
                return .none
            case .didTapClose:
                state.appFacade = windowManager.screenshotAppWindow()
                state.isTransitioning = true
                contentSizeCategoryManager.resetAppContentSizeCategory()
                windowManager.resetAppWindow()
                appViewModel.refresh() // rerun UserLingua.shared.displayString
                return .run { _ in
                    await dismiss()
                }
            case .didTapToggleDarkMode:
                windowManager.toggleDarkMode()
                state.darkModeIsEnabled.toggle()
                return .none
            case .didTapToggleFullScreen:
                state.focusedField = nil
                withAnimation(.linear) {
                    state.isFullScreen.toggle()
                }
                return .none
            case .didTapDoneSuggesting:
                state.focusedField = nil
                return .none
            case .didTapSubmit:
                print("SUBMITTED \(state.makeSuggestion())")
                return .none
            case .onAppear:
                ThemeFont.scaleFactor = contentSizeCategoryManager.systemContentSizeCategory.fontScaleFactor
                return .run { send in
                    try await clock.sleep(for: .seconds(.AnimationDuration.screenTransition))
                    await send(.didAppear)
                }
            case .didAppear:
                state.appFacade = nil
                state.isTransitioning = false
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
            case let .keyboardWillChangeFrame(notification):
                let newHeight = max(0, UIScreen.main.bounds.height - notification.endFrame.origin.y)
                if newHeight != state.keyboardHeight {
                    withAnimation(notification.animation) {
                        state.keyboardHeight = newHeight
                    }
                }
                return .none
            case .observeKeyboardWillChangeFrame:
                return .run { send in
                    let stream = await notificationManager.observe(name: .swizzled(UIResponder.keyboardWillChangeFrameNotification))
                        .compactMap { KeyboardNotification(userInfo: $0.userInfo) }

                    for await keyboardNotification in stream {
                        await send(.keyboardWillChangeFrame(keyboardNotification))
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
            case .recognition, .binding:
                return .none
            }
        }
    }
}

package struct InspectionFeatureView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Dependency(\.locale) var systemLocale
    @Perception.Bindable var store: StoreOf<InspectionFeature>
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
            VStack(spacing: 0) {
                if !store.isFullScreen {
                    header()
                        .zIndex(10)
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
                        }
                    }
                    .environment(\.colorScheme, colorScheme == .dark ? .light : .dark)

                    viewport()
                }

                if !store.isFullScreen {
                    inspectionPanel()
                        .zIndex(10)
                        .transition(.move(edge: .bottom))
                }
            }
            .ignoresSafeArea(edges: ignoredSafeAreaEdges)
            .background {
                if let appFacade = store.appFacade {
                    Image(uiImage: appFacade)
                        .ignoresSafeArea(.all)
                }
            }
            .font(.theme(\.body))
            .clearPresentationBackground()
            .task { await store.send(.observeKeyboardWillChangeFrame).finish() }
            .onAppear { store.send(.onAppear) }
        }
    }

    @ViewBuilder
    func header() -> some View {
        ZStack {
            Text(Strings.Inspection.title)
                .font(.theme(\.headerTitle))
                .frame(maxWidth: .infinity)

            HStack {
                Button(action: { store.send(.didTapClose) }) {
                    Image.theme(\.close)
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
        }
        .padding(.Space.s)
        .background {
            Color.theme(\.background)
                .ignoresSafeArea(.all)
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
        .background(Color.theme(\.background))
    }

    @ViewBuilder
    private func visualPreviewControls() -> some View {
        VStack {
            Spacer()

            HStack(spacing: 0) {
                if store.configuration.appSupportsDynamicType {
                    Button(action: { store.send(.didTapDecreaseTextSize) }) {
                        Image.theme(\.decreaseTextSize)
                            .padding(.Space.s)
                    }

                    Button(action: { store.send(.didTapIncreaseTextSize) }) {
                        Image.theme(\.increaseTextSize)
                            .padding(.Space.s)
                    }
                }

                if store.configuration.appSupportsDarkMode {
                    Button(action: {
                        store.send(.didTapToggleDarkMode)
                    }) {
                        Image.theme(store.darkModeIsEnabled ? \.untoggleDarkMode : \.toggleDarkMode)
                            .padding(.Space.s)
                    }
                }

                Button(action: { store.send(.didTapToggleFullScreen) }) {
                    Image.theme(store.isFullScreen ? \.exitFullScreen : \.enterFullScreen)
                        .padding(.Space.s)
                }
            }
            .padding(.horizontal, .Space.s)
            .background {
                Color.theme(\.background)
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
            .strokeBorder(Color.theme(\.background), lineWidth: .BorderWidth.xl)
            .padding(.horizontal, store.isFullScreen ? 0 : .Space.xs)
            .ignoresSafeArea(.all)
            .background {
                GeometryReader { geometry in
                    Color.clear
                        .onChange(of: geometry.frame(in: .global)) { frame in
                            guard !store.isTransitioning else { return }
                            store.send(.viewportFrameDidChange(frame, animationDuration: .AnimationDuration.quick))
                        }
                        .onChange(of: store.isTransitioning) { _ in
                            guard !store.isTransitioning else { return }
                            store.send(.viewportFrameDidChange(geometry.frame(in: .global), animationDuration: .AnimationDuration.quick))
                        }
                }
            }
    }

    @ViewBuilder
    private func textualPreviewRow(title: Text, string: Text) -> some View {
        VStack(alignment: .leading, spacing: .Space.s) {
            title
                .font(.theme(\.textualPreviewHeading))
                .frame(maxWidth: .infinity, alignment: .leading)

            string
                .font(.theme(\.textualPreviewString))
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
                                        .backgroundColor: UIColor.theme(\.placeholderBackground),
                                        .foregroundColor: UIColor.theme(\.placeholderText)
                                    ],
                                    placeholderTransform: { " \($0) " }
                                )
                            )
                            .background(Color.theme(\.suggestionFieldBackground))
                            .onTapGesture { store.send(.didTapSuggestionPreview) }
                        }
                    }
                    .padding(.Space.s)
                    .background(Color.theme(\.suggestionFieldBackground))
                    .cornerRadius(.Radius.m)

                if focusedField == .suggestion {
                    Button(action: { store.send(.didTapDoneSuggesting) }) {
                        Image.theme(\.doneSuggesting)
                    }
                }
            }

            VStack(alignment: .leading, spacing: .Space.m) {
                if store.recognizedString.isLocalized && Bundle.main.preferredLocalizations.count > 1 {
                    Picker(Strings.Inspection.LocalePicker.title, selection: $store.localeIdentifier) {
                        ForEach(Bundle.main.preferredLocalizations, id: \.self) { identifier in
                            Text(identifier)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if let localization = store.recognizedString.localization {
                    VStack(alignment: .leading, spacing: .Space.xs) {
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
                    .font(.theme(\.localizationDetails))
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
        .background(Color.theme(\.background))
        .bind($store.focusedField, to: $focusedField)
    }

    @ViewBuilder
    private func localizationDetailsRow(_ content: some View) -> some View {
        content
            .padding(.horizontal, .Space.s)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func localizedValueWithHighlightedPlaceholders(locale: Locale) -> AttributedString {
        store.recognizedString.localizedValue(
            locale: locale,
            placeholderAttributes: [
                .backgroundColor: UIColor.theme(\.placeholderBackground),
                .foregroundColor: UIColor.theme(\.placeholderText)
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
