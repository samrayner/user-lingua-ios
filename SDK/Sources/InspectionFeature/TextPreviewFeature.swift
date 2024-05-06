// TextPreviewFeature.swift

import ComposableArchitecture
import Core
import Foundation
import Strings
import SwiftUI
import Theme

@Reducer
package struct TextPreviewFeature {
    @ObservableState
    package struct State: Equatable {
        @Shared(InMemoryKey.configuration) var configuration = .init()
        @Shared(AppStorageKey.textPreviewBaseIsExpanded) var baseIsExpanded = true
        @Shared(AppStorageKey.textPreviewOriginalIsExpanded) var originalIsExpanded = true
        @Shared(AppStorageKey.textPreviewDiffIsExpanded) var diffIsExpanded = true
        @Shared(AppStorageKey.textPreviewSuggestionIsExpanded) var suggestionIsExpanded = true
        @Shared private(set) var recognizedString: RecognizedString
        @Shared private(set) var suggestionString: String
        @Shared private(set) var localeIdentifier: String

        var locale: Locale {
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
    }

    package enum Action: BindableAction {
        case binding(BindingAction<State>)
    }

    package var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { _, action in
            switch action {
            case .binding:
                .none
            }
        }
    }
}

struct TextPreviewFeatureView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Dependency(\.locale) private var systemLocale
    @Perception.Bindable private var store: StoreOf<TextPreviewFeature>

    init(store: StoreOf<TextPreviewFeature>) {
        self.store = store
    }

    var body: some View {
        WithPerceptionTracking {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    TextPreviewSectionView(
                        isExpanded: $store.baseIsExpanded,
                        title: Text(
                            Strings.Inspection.TextPreview.baseTitle(
                                systemLocale.localizedString(forLanguageCode: store.configuration.baseLocale.identifier(.bcp47))
                                    ?? Strings.Inspection.TextPreview.languageNameFallback,
                                store.configuration.baseLocale.identifier(.bcp47)
                            )
                        ),
                        content: Text(localizedValueWithHighlightedPlaceholders(locale: store.configuration.baseLocale))
                    )

                    if store.locale != store.configuration.baseLocale {
                        HorizontalRule()

                        TextPreviewSectionView(
                            isExpanded: $store.originalIsExpanded,
                            title: Text(
                                Strings.Inspection.TextPreview.originalTitle(
                                    systemLocale.localizedString(forLanguageCode: store.localeIdentifier)
                                        ?? Strings.Inspection.TextPreview.languageNameFallback,
                                    store.localeIdentifier
                                )
                            ),
                            content: Text(localizedValueWithHighlightedPlaceholders(locale: store.locale))
                        )
                    }

                    HorizontalRule()

                    TextPreviewSectionView(
                        isExpanded: $store.diffIsExpanded,
                        title: Text(
                            Strings.Inspection.TextPreview.diffTitle(
                                systemLocale.localizedString(forLanguageCode: store.localeIdentifier)
                                    ?? store.localeIdentifier,
                                store.localeIdentifier
                            )
                        ),
                        content: Text(store.diff)
                    )

                    HorizontalRule()

                    TextPreviewSectionView(
                        isExpanded: $store.suggestionIsExpanded,
                        title: Text(
                            Strings.Inspection.TextPreview.suggestionTitle(
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

private struct TextPreviewSectionView: View {
    @Binding var isExpanded: Bool

    let title: Text
    let content: Text

    var body: some View {
        VStack {
            HStack {
                title
                    .font(.theme(\.textPreviewHeading))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image.theme(isExpanded ? \.textPreviewCollapse : \.textPreviewExpand)
                    .foregroundStyle(Color.theme(\.textPreviewToggle))
            }
            .onTapGesture { isExpanded.toggle() }

            if isExpanded {
                content
                    .font(.theme(\.textPreviewString))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, .Space.s)
            }
        }
        .padding(.Space.l)
    }
}
