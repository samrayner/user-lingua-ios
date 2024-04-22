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
    @Dependency(NotificationManagerDependency.self) var notificationManager

    package init() {}

    @ObservableState
    package struct State: Equatable {
        enum Field: String, Hashable {
            case suggestion
        }

        package let recognizedString: RecognizedString
        package var appContentSizeCategory: UIContentSizeCategory
        package var recognition = RecognitionFeature.State()
        var focusedField: Field?
        var suggestionString: String
        var localeIdentifier = Locale.current.identifier.replacingOccurrences(of: "_", with: "-")
        var darkModeIsToggled = false
        var isFullScreen = false
        var headerFrame: CGRect = .zero
        var keyboardPadding: CGFloat = 0

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
        case didTapToggleFullScreen
        case viewportFrameDidChange(CGRect, animationDuration: TimeInterval = 0)
        case headerFrameDidChange(CGRect)
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
                state.keyboardPadding = 0
                return .run { send in
                    await send(.delegate(.didDismiss))
                }
            case .didTapToggleDarkMode:
                state.darkModeIsToggled.toggle()
                windowManager.toggleDarkMode()
                return .none
            case .didTapToggleFullScreen:
                state.focusedField = nil
                // the above should be enough but the keyboard notification fires with
                // a full keyboard endFrame height instead of a height of 0 for some reason
                state.keyboardPadding = 0
                state.isFullScreen.toggle()
                return .none
            case let .viewportFrameDidChange(frame, animationDuration):
                windowManager.translateApp(
                    focusing: state.recognizedString.boundingBoxCenter,
                    in: frame,
                    animationDuration: animationDuration
                )
                return .none
            case let .headerFrameDidChange(frame):
                state.headerFrame = frame
                return .none
            case let .keyboardWillChangeFrame(frame):
                // For some reason the keyboard height is always
                // reported as 75pts when it should be 0.
                state.keyboardPadding = frame.height <= 100 ? 0 : frame.height
                return .none
            case .observeKeyboardWillChangeFrame:
                let keyboardNotificationNames: [Notification.Name] = [
                    .swizzled(UIResponder.keyboardWillChangeFrameNotification),
                    .swizzled(UIResponder.keyboardWillHideNotification),
                    .swizzled(UIResponder.keyboardWillShowNotification)
                ]

                return .run { send in
                    for await notification in await notificationManager.observe(names: keyboardNotificationNames) {
                        if let keyboardNotification = KeyboardNotification(userInfo: notification.userInfo) {
                            await send(
                                .keyboardWillChangeFrame(keyboardNotification.endFrame),
                                animation: keyboardNotification.animation
                            )
                        }
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
    @Perception.Bindable package var store: StoreOf<InspectionFeature>
    @FocusState var focusedField: InspectionFeature.State.Field?

    package init(store: StoreOf<InspectionFeature>) {
        self.store = store
    }

    package var body: some View {
        WithPerceptionTracking {
            ZStack(alignment: .top) {
                RecognitionFeatureView(store: store.scope(state: \.recognition, action: \.recognition))

                VStack(spacing: 0) {
                    // header background colour
                    Color.clear
                        .frame(height: store.isFullScreen ? 0 : store.headerFrame.height)
                        .background {
                            Color.theme(.background)
                                .ignoresSafeArea(edges: .top)
                        }

                    // viewport through to app in UIWindow behind
                    RoundedRectangle(cornerRadius: .Radius.l)
                        .inset(by: -.BorderWidth.xl)
                        .strokeBorder(Color.theme(.background), lineWidth: .BorderWidth.xl)
                        .padding(.horizontal, store.isFullScreen ? 0 : 3)
                        .ignoresSafeArea(.all)
                        .background {
                            GeometryReader { geometry in
                                Color.clear
                                    .onAppear {
                                        store.send(.viewportFrameDidChange(geometry.frame(in: .global)))
                                    }
                                    .onChange(of: geometry.frame(in: .global)) {
                                        store.send(.viewportFrameDidChange($0, animationDuration: 0.3))
                                    }
                            }
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

                        if store.recognizedString.isLocalized {
                            Picker(Strings.Inspection.LanguagePicker.title, selection: $store.localeIdentifier) {
                                ForEach(Bundle.main.preferredLocalizations, id: \.self) { identifier in
                                    Text(Locale.current.localizedString(forIdentifier: identifier) ?? identifier)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(height: 50)
                        }

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
                    .padding(.bottom, store.keyboardPadding)
                    .frame(height: store.isFullScreen ? 0 : nil)
                    .background(Color.theme(.background))
                }
                .ignoresSafeArea(.all, edges: store.isFullScreen ? .all : [])

                HStack {
                    Button(action: { store.send(.didTapClose) }) {
                        Image.theme(.close)
                            .padding(.Space.s)
                    }
                    .background {
                        Color.theme(.background)
                            .opacity(.Opacity.heavy)
                            .cornerRadius(.infinity)
                    }

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
                            Image.theme(store.darkModeIsToggled ? .untoggleDarkMode : .toggleDarkMode)
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
                }
                .padding(.Space.s)
                .background {
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                store.send(.headerFrameDidChange(geometry.frame(in: .local)))
                            }
                            .onChange(of: geometry.frame(in: .local)) {
                                store.send(.headerFrameDidChange($0), animation: .linear(duration: 0.3))
                            }
                    }
                }
            }
            .font(.theme(.body))
            .bind($store.focusedField, to: $focusedField)
            .task { await store.send(.observeKeyboardWillChangeFrame).finish() }
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
