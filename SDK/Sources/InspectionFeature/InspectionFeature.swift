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

    package enum Field: String, Hashable {
        case suggestion
    }

    package enum PreviewMode: String, CaseIterable {
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

    package struct State: Equatable {
        package internal(set) var recognizedString: RecognizedString
        package var locale = Locale.current
        package var suggestionValue: String
        var isInDarkMode: Bool
        var presentation: PresentationState
        var recognition = RecognitionFeature.State()
        var previewMode: PreviewMode = .app
        var focusedField: Field?
        var keyboardHeight: CGFloat = 0
        var viewportFrame: CGRect = .zero
        var isFullScreen = false

        package var isTransitioning: Bool {
            presentation != .presented
        }

        var localizedValue: String {
            recognizedString.localizedValue(locale: locale)
        }

        var diff: AttributedString {
            .init(
                old: localizedValue,
                new: suggestionValue,
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
            appFacade: UIImage?,
            isInDarkMode: Bool
        ) {
            self.recognizedString = recognizedString
            self.suggestionValue = recognizedString.value
            self.presentation = .presenting(appFacade: appFacade)
            self.isInDarkMode = isInDarkMode
        }

        func makeSuggestion() -> Suggestion {
            .init(
                recordedString: recognizedString.recordedString,
                newValue: suggestionValue,
                locale: locale
            )
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
        case onAppear
        case didAppear
        case dismiss(appFacade: UIImage?)
        case setPreviewMode(PreviewMode)
        case setSuggestionValue(String)
        case setFocusedField(Field?)
        case saveSuggestion
        case setLocale(identifier: String)
        case observeOrientation
        case viewportFrameDidChange(CGRect)
        case focusViewport(fromZeroPosition: Bool = false)
        case keyboardWillChangeFrame(KeyboardNotification)
        case observeKeyboardWillChangeFrame
        case recognition(RecognitionFeature.Event)
    }

    package static func reducer() -> ReducerOf<Self> {
        .combine(
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
                case .didTapToggleDarkMode:
                    state.isInDarkMode.toggle()
                case .didTapSubmit:
                    print("SUBMITTED \(state.suggestionValue)")
                case .didTapToggleFullScreen:
                    state.focusedField = nil
                    withAnimation(.linear) {
                        state.isFullScreen.toggle()
                    }
                case .didAppear:
                    state.presentation = .presented
                case let .dismiss(appFacade):
                    state.presentation = .dismissing(appFacade: appFacade)
                case let .setSuggestionValue(value):
                    state.suggestionValue = value
                case let .setLocale(identifier):
                    state.locale = .init(identifier: identifier)
                case let .setPreviewMode(previewMode):
                    state.previewMode = previewMode
                case let .setFocusedField(field):
                    state.focusedField = field
                case let .viewportFrameDidChange(frame):
                    state.viewportFrame = frame
                case let .keyboardWillChangeFrame(notification):
                    let newHeight = max(0, UIScreen.main.bounds.height - notification.endFrame.origin.y)
                    if newHeight != state.keyboardHeight {
                        withAnimation(notification.animation) {
                            state.keyboardHeight = newHeight
                        }
                    }
                case let .recognition(.delegate(.didFinish(result))):
                    switch result {
                    case let .success(recognizedStrings):
                        guard let recognizedString = recognizedStrings.first(
                            where: { $0.recordedString.formatted == state.recognizedString.recordedString.formatted }
                        ) else { return }

                        state.recognizedString = recognizedString
                    case .failure:
                        // do not update recognizedString as was not found on re-recognition
                        // this could be because of keyboard avoidance in the app hiding it from view
                        return
                    }
                case .didTapIncreaseTextSize,
                     .didTapDecreaseTextSize,
                     .onAppear,
                     .observeOrientation,
                     .focusViewport,
                     .observeKeyboardWillChangeFrame,
                     .saveSuggestion,
                     .recognition:
                    return
                }
            }
        )
    }

    package static func feedback() -> FeedbackOf<Self> {
        let stateFeedback = FeedbackOf<Self>.combine(
            .state(\.presentation) { presentation, _, dependencies in
                switch presentation {
                case .preparingToDismiss:
                    let appFacade = dependencies.windowService.screenshotAppWindow()
                    dependencies.contentSizeCategoryService.resetAppContentSizeCategory()
                    dependencies.windowService.resetAppWindow()
                    dependencies.appViewModel.refresh() // rerun UserLingua.shared.displayString
                    return .send(.dismiss(appFacade: appFacade))
                case .presenting, .presented, .dismissing:
                    return .none
                }
            },
            .state(\.viewportFrame) { _, _, _ in
                .send(.focusViewport())
            },
            .state(\.recognizedString) { _, _, _ in
                .send(.focusViewport(fromZeroPosition: true))
            },
            .state(\.suggestionValue) { _, _, _ in
                .send(.saveSuggestion) // TODO: debounce
            },
            .state(\.isInDarkMode) { _, _, dependencies in
                dependencies.windowService.toggleDarkMode()
                return .none
            },
            .state(\.locale) { _, state, dependencies in
                let suggestionValue = dependencies.suggestionsRepository.suggestion(
                    for: state.recognizedString.value,
                    locale: state.locale
                )?.newValue ?? state.localizedValue
                return .send(.setSuggestionValue(suggestionValue))
            }
        )

        let eventFeedback = FeedbackOf<Self>.combine(
            .event(/Event.didTapDecreaseTextSize) { _, _, dependencies in
                dependencies.contentSizeCategoryService.decrementAppContentSizeCategory()
                return .none
            },
            .event(/Event.observeOrientation) { _, _, dependencies in
                .publish(
                    dependencies.orientationService
                        .orientationDidChange()
                        .map { _ in .recognition(.start) }
                        .eraseToAnyPublisher()
                )
            },
            .event(/Event.observeKeyboardWillChangeFrame) { _, _, dependencies in
                .publish(
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

                return .none
            },
            .event(/Event.onAppear) { _, _, _ in
                .publish(
                    Publishers.Merge(
                        [Event.observeKeyboardWillChangeFrame, Event.observeOrientation].publisher,
                        Just(Event.didAppear).delay(for: .seconds(.AnimationDuration.screenTransition), scheduler: RunLoop.main)
                    )
                    .eraseToAnyPublisher()
                )
            },
            .event(/Event.saveSuggestion) { _, state, dependencies in
                dependencies.suggestionsRepository.saveSuggestion(state.makeSuggestion())
                dependencies.appViewModel.refresh()
                return .none
            }
        )

        return .combine(stateFeedback, eventFeedback)
    }
}

package struct InspectionFeatureView: View {
    private let store: StoreOf<InspectionFeature>
    @FocusState private var focusedField: InspectionFeature.Field?
    @Environment(\.dismiss) var dismiss

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
        WithViewStore(store) { store in
            VStack(spacing: 0) {
                if !store.isFullScreen {
                    header(store: store)
                        .zIndex(10)
                        .transition(.move(edge: .top))
                }

                ZStack {
                    Group {
                        switch store.previewMode {
                        case .app:
                            AppPreviewFeatureView(store: self.store)
                        case .text:
                            TextPreviewFeatureView(store: self.store)
                        }
                    }

                    viewport(store: store)
                }

                if !store.isFullScreen {
                    inspectionPanel(store: store)
                        .zIndex(10)
                        .transition(.move(edge: .bottom))
                }
            }
            .ignoresSafeArea(edges: ignoredSafeAreaEdges)
            .background {
                switch store.presentation {
                case let .presenting(appFacade), let .dismissing(appFacade):
                    appFacade.map { Image(uiImage: $0).ignoresSafeArea() }
                default:
                    EmptyView()
                }
            }
            .font(.theme(\.body))
            .clearPresentationBackground()
            .onAppear { store.send(.onAppear) }
            .onReceive(store.publisher(for: \.presentation)) {
                guard case .dismissing = $0 else { return }
                dismiss()
            }
        }
    }

    @ViewBuilder
    func header(store: ViewStoreOf<InspectionFeature>) -> some View {
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

                Picker(
                    Strings.Inspection.PreviewModePicker.title,
                    selection: store.binding(
                        get: \.previewMode,
                        send: { .setPreviewMode($0) }
                    )
                ) {
                    ForEach(InspectionFeature.PreviewMode.allCases, id: \.self) { previewMode in
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
    private func viewport(store: ViewStoreOf<InspectionFeature>) -> some View {
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
    private func inspectionPanel(store: ViewStoreOf<InspectionFeature>) -> some View {
        VStack(alignment: .leading, spacing: .Space.m) {
            HStack(spacing: .Space.m) {
                TextField(
                    Strings.Inspection.SuggestionField.placeholder,
                    text: store.binding(
                        get: \.suggestionValue,
                        send: { .setSuggestionValue($0) }
                    ),
                    axis: .vertical
                )
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($focusedField, equals: .suggestion)
                .frame(maxWidth: .infinity, minHeight: 30)
                .overlay(alignment: .leading) {
                    if focusedField != .suggestion && store.suggestionValue == store.localizedValue {
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
                    Picker(
                        Strings.Inspection.LocalePicker.title,
                        selection: store.binding(
                            get: { $0.locale.identifier(.bcp47) },
                            send: { .setLocale(identifier: $0) }
                        )
                    ) {
                        ForEach(Bundle.main.preferredLocalizations, id: \.self) { identifier in
                            Text(identifier)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if let localization = store.recognizedString.localization {
                    VStack(alignment: .leading, spacing: .Space.xs) {
                        (Text("\(Strings.Inspection.Localization.Key.title): ").bold() + Text(localization.key))
                            .padding(.horizontal, .Space.s)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        (Text("\(Strings.Inspection.Localization.Table.title): ")
                            .bold() + Text("\(localization.tableName ?? "Localizable").strings"))
                            .padding(.horizontal, .Space.s)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if let comment = localization.comment {
                            (Text("\(Strings.Inspection.Localization.Comment.title): ").bold() + Text(comment))
                                .padding(.horizontal, .Space.s)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .font(.theme(\.localizationDetails))
                }

                if store.suggestionValue != store.localizedValue {
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
        .bind(store.binding(get: \.focusedField, send: { .setFocusedField($0) }), to: $focusedField)
    }
}
