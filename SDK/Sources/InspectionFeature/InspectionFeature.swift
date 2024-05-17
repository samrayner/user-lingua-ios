// InspectionFeature.swift

import ComposableArchitecture
import Core
import Diff
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

        enum PreviewMode: String, CaseIterable {
            case text
            case app

            var icon: Image {
                switch self {
                case .text:
                    Image.theme(\.textPreviewMode)
                case .app:
                    Image.theme(\.appPreviewMode)
                }
            }
        }

        package internal(set) var recognizedString: RecognizedString
        var suggestionString: String
        package internal(set) var isTransitioning = true
        @Shared(InMemoryKey.recognitionState) var recognition = .init()
        @Shared(InMemoryKey.configuration) var configuration = .init()
        @Shared(AppStorageKey.previewMode) var previewMode: PreviewMode = .app
        var focusedField: Field?
        var keyboardHeight: CGFloat = 0
        var appFacade: UIImage?
        var viewportFrame: CGRect = .zero
        var isFullScreen = false
        var localeIdentifier = Locale.current.identifier(.bcp47)

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
            self.appFacade = appFacade
            self.recognizedString = recognizedString
            self.suggestionString = recognizedString.value
        }
    }

    package enum Action: BindableAction {
        case didTapSuggestionPreview
        case didTapClose
        case didTapDoneSuggesting
        case didTapSubmit
        case didTapIncreaseTextSize
        case didTapDecreaseTextSize
        case didTapToggleDarkMode
        case didTapToggleFullScreen
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
            case .didTapIncreaseTextSize:
                contentSizeCategoryService.incrementAppContentSizeCategory()
                return .none
            case .didTapDecreaseTextSize:
                contentSizeCategoryService.decrementAppContentSizeCategory()
                return .none
            case .didTapToggleDarkMode:
                windowService.toggleDarkMode()
                return .none
            case .didTapToggleFullScreen:
                state.focusedField = nil
                withAnimation(.linear) {
                    state.isFullScreen.toggle()
                }
                return .none
            case .onAppear:
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
                    within: state.viewportFrame,
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
            case .recognition, .binding:
                return .none
            }
        }
    }
}

package struct InspectionFeatureView: View {
    @Dependency(WindowServiceDependency.self) private var windowService
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
                        case .app:
                            AppPreviewFeatureView(
                                store: store,
                                isInDarkMode: windowService.appUIStyle == .dark
                            )
                        case .text:
                            TextPreviewFeatureView(store: store)
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
}
