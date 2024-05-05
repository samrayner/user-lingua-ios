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
    @Dependency(ContentSizeCategoryServiceDependency.self) var contentSizeCategoryService
    @Dependency(WindowServiceDependency.self) var windowService
    @Dependency(NotificationServiceDependency.self) var notificationService
    @Dependency(OrientationServiceDependency.self) var orientationService

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

        package internal(set) var recognizedString: RecognizedString
        @Shared var isFullScreen: Bool
        @Shared(RecognitionFeature.State.persistenceKey) var recognition = .init()
        @Shared(Configuration.persistenceKey) var configuration = .init()
        package internal(set) var isTransitioning = true
        var focusedField: Field?
        var suggestionString: String
        var localeIdentifier = Locale.current.identifier.replacingOccurrences(of: "_", with: "-")
        var keyboardHeight: CGFloat = 0
        var appFacade: UIImage?
        var viewportFrame: CGRect = .zero
        var previewMode: PreviewMode = .visual
        var visualPreview: VisualPreviewFeature.State
        // TODO: var textualPreview: TextualPreviewFeature.State = .init()

        package var locale: Locale {
            Locale(identifier: localeIdentifier)
        }

        var localizedValue: String {
            recognizedString.localizedValue(locale: locale)
        }

        var diff: AttributedString {
            .init(
                old: localizedValue,
                new: suggestionString,
                diffAttributes: .init(
                    insert: [
                        .foregroundColor: UIColor.theme(\.diffInsertion),
                        .underlineColor: UIColor.theme(\.diffInsertion),
                        .underlineStyle: NSUnderlineStyle.single.rawValue
                    ],
                    delete: [
                        .foregroundColor: UIColor.theme(\.diffDeletion),
                        .strikethroughColor: UIColor.theme(\.diffDeletion),
                        .strikethroughStyle: NSUnderlineStyle.single.rawValue
                    ]
                )
            )
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
            appFacade: UIImage?
        ) {
            self.recognizedString = recognizedString
            self.appFacade = appFacade
            self.suggestionString = recognizedString.value

            let isFullScreen = Shared<Bool>(false)

            self._isFullScreen = isFullScreen
            self.visualPreview = .init(isFullScreen: isFullScreen)
        }
    }

    package enum Action: BindableAction {
        case didTapSuggestionPreview
        case didTapClose
        case didTapDoneSuggesting
        case didTapSubmit
        case onAppear
        case didAppear
        case saveSuggestion
        case observeOrientation
        case orientationDidChange(UIDeviceOrientation)
        case viewportFrameDidChange(CGRect)
        case focusViewport(fromZeroPosition: Bool = false)
        case keyboardWillChangeFrame(KeyboardNotification)
        case observeKeyboardWillChangeFrame
        case binding(BindingAction<State>)
        case recognition(RecognitionFeature.Action)
        case visualPreview(VisualPreviewFeature.Action)
        // TODO: case textualPreview(TextualPreviewFeature.Action)
    }

    enum CancelID {
        case suggestionSaveDebounce
    }

    package var body: some ReducerOf<Self> {
        BindingReducer()

        Scope(state: \.recognition, action: \.recognition) {
            RecognitionFeature()
        }

        Scope(state: \.visualPreview, action: \.visualPreview) {
            VisualPreviewFeature()
        }

        // TODO:
//        Scope(state: \.textualPreview, action: \.textualPreview) {
//            TextualPreviewFeature()
//        }

        Reduce { state, action in
            switch action {
            case .didTapSuggestionPreview:
                state.focusedField = .suggestion
                return .none
            case .didTapClose:
                state.appFacade = windowService.screenshotAppWindow()
                state.isTransitioning = true
                contentSizeCategoryService.resetAppContentSizeCategory()
                windowService.resetAppWindow()
                appViewModel.refresh() // rerun UserLingua.shared.displayString
                return .run { _ in
                    await dismiss()
                }
            case .didTapDoneSuggesting:
                state.focusedField = nil
                return .none
            case .didTapSubmit:
                print("SUBMITTED \(state.makeSuggestion())")
                return .none
            case .onAppear:
                ThemeFont.scaleFactor = contentSizeCategoryService.systemContentSizeCategory.fontScaleFactor
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
            case .observeOrientation:
                return .run { send in
                    for await orientation in await orientationService.orientationDidChange() {
                        await send(.orientationDidChange(orientation))
                    }
                }
            case .orientationDidChange:
                return .run { send in
                    await send(.recognition(.start))
                }
            case .visualPreview(.delegate(.didTapToggleFullScreen)):
                state.focusedField = nil
                withAnimation(.linear) {
                    state.isFullScreen.toggle()
                }
                return .none
            case let .recognition(.delegate(.didRecognizeStrings(recognizedStrings))):
                guard let recognizedString = recognizedStrings.first(
                    where: { $0.recordedString.formatted == state.recognizedString.recordedString.formatted }
                ) else { return .none }

                state.recognizedString = recognizedString
                return .run { send in
                    await send(.focusViewport(fromZeroPosition: true))
                }
            case let .viewportFrameDidChange(frame):
                state.viewportFrame = frame
                return .run { send in
                    await send(.focusViewport())
                }
            case let .focusViewport(fromZeroPosition):
                if fromZeroPosition {
                    windowService.resetAppPosition()
                }

                windowService.positionApp(
                    focusing: state.recognizedString.boundingBoxCenter,
                    in: state.viewportFrame,
                    animationDuration: .AnimationDuration.quick
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
                    let stream = await notificationService.observe(name: .swizzled(UIResponder.keyboardWillChangeFrameNotification))
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
            case .recognition, .visualPreview, .binding: // TODO: .textualPreview
                return .none
            }
        }
    }
}

package struct InspectionFeatureView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Dependency(WindowServiceDependency.self) private var windowService
    @Dependency(\.locale) private var systemLocale
    @Perception.Bindable private var store: StoreOf<InspectionFeature>
    @FocusState private var focusedField: InspectionFeature.State.Field?

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
                        switch store.previewMode {
                        case .visual:
                            VisualPreviewFeatureView(
                                store: store.scope(state: \.visualPreview, action: \.visualPreview),
                                isInDarkMode: windowService.appUIStyle == .dark
                            )
                        case .textual:
                            textualPreview()
                        }
                    }

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
            .onAppear { store.send(.onAppear) }
            .task { await store.send(.observeKeyboardWillChangeFrame).finish() }
            .task { await store.send(.observeOrientation).finish() }
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
                TextualPreviewRowView(
                    isExpanded: .constant(true),
                    title: Text(
                        Strings.Inspection.TextualPreview.baseTitle(
                            systemLocale.localizedString(forLanguageCode: store.configuration.baseLocale.identifier(.bcp47))
                                ?? Strings.Inspection.TextualPreview.languageNameFallback,
                            store.configuration.baseLocale.identifier(.bcp47)
                        )
                    ),
                    content: Text(localizedValueWithHighlightedPlaceholders(locale: store.configuration.baseLocale))
                )

                if store.locale != store.configuration.baseLocale {
                    HorizontalRule()

                    TextualPreviewRowView(
                        isExpanded: .constant(true),
                        title: Text(
                            Strings.Inspection.TextualPreview.originalTitle(
                                systemLocale.localizedString(forLanguageCode: store.localeIdentifier)
                                    ?? Strings.Inspection.TextualPreview.languageNameFallback,
                                store.localeIdentifier
                            )
                        ),
                        content: Text(localizedValueWithHighlightedPlaceholders(locale: store.locale))
                    )
                }

                HorizontalRule()

                TextualPreviewRowView(
                    isExpanded: .constant(true),
                    title: Text(
                        Strings.Inspection.TextualPreview.diffTitle(
                            systemLocale.localizedString(forLanguageCode: store.localeIdentifier)
                                ?? store.localeIdentifier,
                            store.localeIdentifier
                        )
                    ),
                    content: Text(store.diff)
                )

                HorizontalRule()

                TextualPreviewRowView(
                    isExpanded: .constant(true),
                    title: Text(
                        Strings.Inspection.TextualPreview.suggestionTitle(
                            systemLocale.localizedString(forLanguageCode: store.localeIdentifier)
                                ?? store.localeIdentifier,
                            store.localeIdentifier
                        )
                    ),
                    content: Text(store.suggestionString)
                )
            }
        }
        .background(Color.theme(\.background))
        .environment(\.colorScheme, colorScheme == .dark ? .light : .dark)
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
                            store.send(.viewportFrameDidChange(frame))
                        }
                        .onChange(of: store.isTransitioning) { _ in
                            guard !store.isTransitioning else { return }
                            store.send(.viewportFrameDidChange(geometry.frame(in: .global)))
                        }
                }
            }
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
