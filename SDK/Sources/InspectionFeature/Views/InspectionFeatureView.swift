// InspectionFeatureView.swift

import CombineFeedback
import Core
import Dependencies
import Foundation
import Strings
import SwiftUI
import Theme

package struct InspectionFeatureView: View {
    typealias Event = InspectionFeature.Event

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var orientationService: ViewDependency<OrientationServiceProtocol>

    private let store: StoreOf<InspectionFeature>
    @FocusState private var focusedField: InspectionFeature.Field?

    package init(store: StoreOf<InspectionFeature>) {
        self.store = store
    }

    private var ignoredSafeAreaEdges: Edge.Set {
        if store.state.isFullScreen {
            .all
        } else if store.state.keyboardHeight > 0 {
            .bottom
        } else {
            []
        }
    }

    package var body: some View {
        WithViewStore(store) { state in
            VStack(spacing: 0) {
                if !state.isFullScreen {
                    header(state: state)
                        .zIndex(10)
                        .transition(.move(edge: .top))
                }

                ZStack {
                    Group {
                        switch state.previewMode {
                        case .app:
                            AppPreviewFeatureView(store: store)
                        case .text:
                            TextPreviewFeatureView(store: store)
                        }
                    }

                    viewport(state: state)
                }

                if !state.isFullScreen {
                    inspectionPanel(state: state)
                        .zIndex(10)
                        .transition(.move(edge: .bottom))
                }
            }
            .ignoresSafeArea(edges: ignoredSafeAreaEdges)
            .background {
                switch state.presentation {
                case let .presenting(appFacade), let .dismissing(appFacade):
                    appFacade.map { Image(uiImage: $0).ignoresSafeArea() }
                default:
                    EmptyView()
                }
            }
            .font(.theme(\.body))
            .clearPresentationBackground()
            .onAppear { store.send(.onAppear) }
            .onReceive(state.publisher(for: \.presentation)) {
                guard case .dismissing = $0 else { return }
                dismiss()
            }
            .onReceive(orientationService.dependency.orientationDidChange()) {
                store.send(.orientationDidChange($0))
            }
            .onReceive(
                NotificationCenter.default
                    .publisher(for: .swizzled(UIResponder.keyboardWillChangeFrameNotification))
                    .compactMap { KeyboardNotification(userInfo: $0.userInfo) }
            ) {
                store.send(.keyboardWillChangeFrame($0))
            }
        }
    }

    @ViewBuilder
    func header(state _: ViewStoreOf<InspectionFeature>) -> some View {
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
                        send: Event.setPreviewMode
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
    private func viewport(state: ViewStoreOf<InspectionFeature>) -> some View {
        RoundedRectangle(cornerRadius: .Radius.l)
            .inset(by: -.BorderWidth.xl)
            .strokeBorder(Color.theme(\.background), lineWidth: .BorderWidth.xl)
            .padding(.horizontal, state.isFullScreen ? 0 : .Space.xs)
            .ignoresSafeArea(.all)
            .background {
                GeometryReader { geometry in
                    Color.clear
                        .onChange(of: geometry.frame(in: .global)) { frame in
                            guard !state.isTransitioning else { return }
                            store.send(.viewportFrameDidChange(frame))
                        }
                        .onChange(of: state.isTransitioning) { _ in
                            guard !state.isTransitioning else { return }
                            store.send(.viewportFrameDidChange(geometry.frame(in: .global)))
                        }
                }
            }
    }

    @ViewBuilder
    private func inspectionPanel(state: ViewStoreOf<InspectionFeature>) -> some View {
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
                    if focusedField != .suggestion && state.suggestionValue == state.localizedValue {
                        Text(
                            state.recognizedString.localizedValue(
                                locale: state.locale,
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
                if state.recognizedString.isLocalized && Bundle.main.preferredLocalizations.count > 1 {
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

                if let localization = state.recognizedString.localization {
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

                if state.suggestionValue != state.localizedValue {
                    Button(action: { store.send(.didTapSubmit) }) {
                        Text(Strings.Inspection.submitButton)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.primary)
                }
            }
            .frame(minHeight: state.keyboardHeight)
        }
        .padding(.top, .Space.m)
        .padding(.bottom, .Space.s)
        .padding(.horizontal, .Space.m)
        .background(Color.theme(\.background))
        .bind(store.binding(get: \.focusedField, send: Event.setFocusedField), to: $focusedField)
    }
}
