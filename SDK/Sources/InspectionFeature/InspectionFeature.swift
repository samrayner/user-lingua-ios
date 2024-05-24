// InspectionFeature.swift

import CasePaths
import Combine
import CombineFeedback
import Core
import Diff
import Foundation
import RecognitionFeature
import Strings
import SwiftUI
import Theme

package enum InspectionFeature: Feature {
    package struct Dependencies {
        let notificationCenter: NotificationCenter
        let windowService: any WindowServiceProtocol
        let appViewModel: any UserLinguaObservableProtocol
        let contentSizeCategoryService: any ContentSizeCategoryServiceProtocol
        let orientationService: any OrientationServiceProtocol
        let suggestionsRepository: any SuggestionsRepositoryProtocol
    }

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

        package enum PresentationState: Equatable {
            case presenting(appFacade: UIImage?)
            case presented
            case preparingToDismiss
            case dismissing(appFacade: UIImage?)
        }

        package internal(set) var recognizedString: RecognizedString
        var suggestion: Suggestion?
        var presentation: PresentationState
        var recognition = RecognitionFeature.State()
        var configuration = Configuration()
        var previewMode: PreviewMode = .app
        var focusedField: Field?
        var keyboardHeight: CGFloat = 0
        var viewportFrame: CGRect = .zero
        var isFullScreen = false
        var locale = Locale.current

        package var isTransitioning: Bool {
            presentation != .presented
        }

//        var localeIdentifierBinding: Binding<String> {
//            Binding(
//                get: {
//                    locale.identifier(.bcp47)
//                },
//                set: { newValue in
//                    locale = .init(identifier: newValue)
//                }
//            )
//        }

//        var suggestionStringBinding: Binding<String> {
//            Binding(
//                get: {
//                    suggestion?.newValue ?? ""
//                },
//                set: { newValue in
//                    suggestion = .init(
//                        recordedString: recognizedString.recordedString,
//                        newValue: newValue,
//                        locale: locale
//                    )
//                }
//            )
//        }

        var localizedValue: String {
            recognizedString.localizedValue(locale: locale)
        }

        var diff: AttributedString {
            .init(
                old: localizedValue,
                new: suggestion?.newValue ?? "",
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

        package init(
            recognizedString: RecognizedString,
            appFacade: UIImage
        ) {
            self.recognizedString = recognizedString
            self.presentation = .presenting(appFacade: appFacade)
        }
    }

    package enum Event {
        case didTapSuggestionPreview
        case didTapClose
        case didTapDoneSuggesting
        case didTapSubmit
        case didTapIncreaseTextSize
        case didTapDecreaseTextSize
        case didTapToggleDarkMode
        case didTapToggleFullScreen
        case didAppear
        case dismiss(appFacade: UIImage?)
        case setSuggestion(Suggestion)
        case saveSuggestion(Suggestion)
        case observeOrientation
        case viewportFrameDidChange(CGRect)
        case focusViewport(fromZeroPosition: Bool = false)
        case keyboardWillChangeFrame(KeyboardNotification)
        case observeKeyboardWillChangeFrame
        case localeDidChange(Locale)
        case recognition(RecognitionFeature.Event)
    }

    enum CancelID {
        case suggestionSaveDebounce
    }

    package static func reducer() -> ReducerOf<Self> {
        Reducer.combine(
            RecognitionFeature.reducer()
                .pullback(state: \State.recognition, event: /Event.recognition),

            ReducerOf<Self> { state, event in
                switch event {
                case .didTapSuggestionPreview:
                    state.focusedField = .suggestion
                case .didTapClose:
                    state.presentation = .preparingToDismiss
                case .didTapDoneSuggesting:
                    state.focusedField = nil
                case .didTapSubmit:
                    print("SUBMITTED \(state.suggestion)")
                case .didTapToggleFullScreen:
                    state.focusedField = nil
                    withAnimation(.linear) {
                        state.isFullScreen.toggle()
                    }
                case .didAppear:
                    state.presentation = .presented
                case let .dismiss(appFacade):
                    state.presentation = .dismissing(appFacade: appFacade)
                case let .updateSuggestion(suggestion):
                    state.suggestion = suggestion
                case let .recognition(.delegate(.didRecognizeStrings(recognizedStrings))):
                    guard let recognizedString = recognizedStrings.first(
                        where: { $0.recordedString.formatted == state.recognizedString.recordedString.formatted }
                    ) else { return }

                    state.recognizedString = recognizedString
                case let .viewportFrameDidChange(frame):
                    state.viewportFrame = frame
                case let .keyboardWillChangeFrame(notification):
                    let newHeight = max(0, UIScreen.main.bounds.height - notification.endFrame.origin.y)
                    if newHeight != state.keyboardHeight {
                        withAnimation(notification.animation) {
                            state.keyboardHeight = newHeight
                        }
                    }
                case .recognition,
                     .didTapIncreaseTextSize,
                     .didTapDecreaseTextSize,
                     .didTapToggleDarkMode:
                    break
                }
            }
        )
    }

    package static func feedback() -> FeedbackOf<Self> {
        .combine(
            .state(\.presentation) { presentation, dependencies in
                switch presentation {
                case .preparingToDismiss:
                    let appFacade = dependencies.windowService.screenshotAppWindow()
                    dependencies.contentSizeCategoryService.resetAppContentSizeCategory()
                    dependencies.windowService.resetAppWindow()
                    dependencies.appViewModel.refresh() // rerun UserLingua.shared.displayString
                    return .run { send in
                        send(.dismiss(appFacade: appFacade))
                    }
                case .presenting, .presented, .dismissing:
                    return .none
                }
            },
            .state(\.viewportFrame) { _, _ in
                .run { send in
                    send(.focusViewport())
                }
            },
            .state(\.recognizedString) { _, _ in
                .run { send in
                    send(.focusViewport(fromZeroPosition: true))
                }
            },
            .state(\.suggestion) { suggestion, dependencies in
                dependencies.appViewModel.refresh()
                dependencies.suggestionsRepository.saveSuggestion(suggestion) // TODO: debounce
                return .none
            },
            .event(/Event.didTapDecreaseTextSize) { _, _, dependencies in
                dependencies.contentSizeCategoryService.decrementAppContentSizeCategory()
                return .none
            },
            .event(/Event.didTapToggleDarkMode) { _, _, dependencies in
                dependencies.windowService.toggleDarkMode()
                return .none
            },
            .event(/Event.observeOrientation) { _, _, dependencies in
                .observe(
                    dependencies.orientationService
                        .orientationDidChange()
                        .map { _ in .recognition(.start) }
                        .eraseToAnyPublisher()
                )
            },
            .event(/Event.observeKeyboardWillChangeFrame) { _, _, dependencies in
                .observe(
                    dependencies.notificationCenter
                        .publisher(for: .swizzled(UIResponder.keyboardWillChangeFrameNotification))
                        .compactMap { KeyboardNotification(userInfo: $0.userInfo) }
                        .map { .keyboardWillChangeFrame($0) }
                        .eraseToAnyPublisher()
                )
            },
            .event(/Event.focusViewport) { fromZeroPosition, state, dependencies in
                if fromZeroPosition {
                    dependencies.windowService.resetAppPosition()
                }

                dependencies.windowService.positionApp(
                    focusing: state.recognizedString.boundingBoxCenter,
                    within: state.viewportFrame,
                    animationDuration: .AnimationDuration.quick
                )
            },
            .event(/Event.localeDidChange) { _, state, dependencies in
                let suggestion = dependencies.suggestionsRepository.suggestion(
                    for: state.recognizedString.value,
                    locale: state.locale
                )
                return .run { send in
                    send(.updateSuggestion(suggestion))
                }
            }
        )
    }
}

package struct InspectionFeatureView: View {
    private var store: StoreOf<InspectionFeature>
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
            .onAppear {
                Task {
                    await store.send(.observeKeyboardWillChangeFrame)
                    await store.send(.observeOrientation)
                    await Task.sleep(for: .seconds(0.4))
                    await store.send(.didAppear)
                }
            }
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
