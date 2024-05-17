// AppPreviewFeatureView.swift

import ComposableArchitecture
import Core
import Foundation
import SwiftUI
import Theme

struct AppPreviewFeatureView: View {
    private let store: StoreOf<InspectionFeature>
    @State private var isInDarkMode: Bool

    init(
        store: StoreOf<InspectionFeature>,
        isInDarkMode: Bool
    ) {
        self.store = store
        self._isInDarkMode = .init(initialValue: isInDarkMode)
    }

    var body: some View {
        WithPerceptionTracking {
            VStack {
                Spacer()

                HStack(spacing: 0) {
                    if store.configuration.appSupportsDynamicType {
                        Button(action: { store.send(.didTapDecreaseTextSize) }) {
                            Image.theme(\.decreaseTextSize)
                                .padding(.Space.s)
                        }

                        Button(action: { store.send(.didTapIncreaseTextSize) }) {
                            Image.theme(\.increaseTextSize)
                                .padding(.Space.s)
                        }
                    }

                    if store.configuration.appSupportsDarkMode {
                        Button(action: {
                            store.send(.didTapToggleDarkMode)
                            isInDarkMode.toggle()
                        }) {
                            Image.theme(\.toggleDarkMode)
                                .padding(.Space.s)
                        }
                    }

                    Button(action: { store.send(.didTapToggleFullScreen) }) {
                        Image.theme(store.isFullScreen ? \.exitFullScreen : \.enterFullScreen)
                            .padding(.Space.s)
                    }
                }
                .padding(.horizontal, .Space.s)
                .background {
                    Color.theme(\.background)
                        .opacity(.Opacity.heavy)
                        .cornerRadius(.infinity)
                }
                .padding(.Space.m)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .environment(\.colorScheme, isInDarkMode ? .light : .dark)
        }
    }
}
