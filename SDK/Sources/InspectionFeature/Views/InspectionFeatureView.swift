// InspectionFeatureView.swift

import CombineFeedback
import Core
import Dependencies
import Foundation
import Strings
import SwiftUI
import Theme

package struct InspectionFeatureView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var orientationService: ViewDependency<OrientationServiceProtocol>

    private let store: StoreOf<InspectionFeature>
    @FocusState private var focusedField: InspectionFeature.Field?

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
