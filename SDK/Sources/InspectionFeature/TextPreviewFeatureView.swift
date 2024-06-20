// TextPreviewFeatureView.swift

import CombineFeedback
import Core
import Foundation
import Strings
import SwiftUI
import Theme

struct TextPreviewFeatureView: View {
    @ObservedObject private(set) var configuration: Configuration = .init() // TODO: inject configuration
    @Environment(\.colorScheme) private var colorScheme
    private let store: StoreOf<InspectionFeature>
    private let systemLocale: Locale
    @AppStorage(UserDefaults.Keys.textPreviewBaseIsExpanded) var baseIsExpanded = true
    @AppStorage(UserDefaults.Keys.textPreviewOriginalIsExpanded) var originalIsExpanded = true
    @AppStorage(UserDefaults.Keys.textPreviewDiffIsExpanded) var diffIsExpanded = true
    @AppStorage(UserDefaults.Keys.textPreviewSuggestionIsExpanded) var suggestionIsExpanded = true

    init(
        store: StoreOf<InspectionFeature>,
        systemLocale: Locale = Locale.current
    ) {
        self.store = store
        self.systemLocale = systemLocale
    }

    var body: some View {
        WithViewStore(store) { store in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    TextPreviewSectionView(
                        isExpanded: $baseIsExpanded,
                        title: Text(
                            Strings.Inspection.TextPreview.baseTitle(
                                systemLocale.localizedString(forLanguageCode: configuration.baseLocale.identifier(.bcp47))
                                    ?? Strings.Inspection.TextPreview.languageNameFallback,
                                configuration.baseLocale.identifier(.bcp47)
                            )
                        ),
                        content: Text(localizedValueWithHighlightedPlaceholders(locale: configuration.baseLocale))
                    )

                    if store.locale != configuration.baseLocale {
                        HorizontalRule()

                        TextPreviewSectionView(
                            isExpanded: $originalIsExpanded,
                            title: Text(
                                Strings.Inspection.TextPreview.originalTitle(
                                    systemLocale.localizedString(forLanguageCode: store.locale.identifier)
                                        ?? Strings.Inspection.TextPreview.languageNameFallback,
                                    store.locale.identifier
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
                                systemLocale.localizedString(forLanguageCode: store.locale.identifier)
                                    ?? store.locale.identifier,
                                store.locale.identifier
                            )
                        ),
                        content: Text(store.diff)
                    )

                    HorizontalRule()

                    TextPreviewSectionView(
                        isExpanded: $suggestionIsExpanded,
                        title: Text(
                            Strings.Inspection.TextPreview.suggestionTitle(
                                systemLocale.localizedString(forLanguageCode: store.locale.identifier)
                                    ?? store.locale.identifier,
                                store.locale.identifier
                            )
                        ),
                        content: Text(store.suggestionValue)
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
