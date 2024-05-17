// TextPreviewFeatureView.swift

import ComposableArchitecture
import Core
import Foundation
import Strings
import SwiftUI
import Theme

struct TextPreviewFeatureView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Dependency(\.locale) private var systemLocale
    @Perception.Bindable private var store: StoreOf<InspectionFeature>
    @AppStorage(UserDefaults.Keys.textPreviewBaseIsExpanded) var baseIsExpanded = true
    @AppStorage(UserDefaults.Keys.textPreviewOriginalIsExpanded) var originalIsExpanded = true
    @AppStorage(UserDefaults.Keys.textPreviewDiffIsExpanded) var diffIsExpanded = true
    @AppStorage(UserDefaults.Keys.textPreviewSuggestionIsExpanded) var suggestionIsExpanded = true

    init(store: StoreOf<InspectionFeature>) {
        self.store = store
    }

    var body: some View {
        WithPerceptionTracking {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    TextPreviewSectionView(
                        isExpanded: $baseIsExpanded,
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
                            isExpanded: $originalIsExpanded,
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
                        isExpanded: $diffIsExpanded,
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
                        isExpanded: $suggestionIsExpanded,
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
