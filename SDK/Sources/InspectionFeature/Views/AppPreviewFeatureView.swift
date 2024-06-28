// AppPreviewFeatureView.swift

import CombineFeedback
import Core
import Foundation
import SwiftUI
import Theme

struct AppPreviewFeatureView: View {
    @EnvironmentObject var configuration: ViewDependency<Configuration>
    private let store: StoreOf<InspectionFeature>

    init(store: StoreOf<InspectionFeature>) {
        self.store = store
    }

    struct BodyState: Equatable, Scoped {
        typealias Parent = InspectionFeature.State
        let isFullScreen: Bool
        let appIsInDarkMode: Bool
    }

    var body: some View {
        WithViewStore(store, scope: BodyState.init) { state in
            VStack {
                Spacer()

                HStack(spacing: 0) {
                    if configuration.appSupportsDynamicType {
                        Button(action: { store.send(.didTapDecreaseTextSize) }) {
                            Image.theme(\.decreaseTextSize)
                                .padding(.Space.s)
                        }

                        Button(action: { store.send(.didTapIncreaseTextSize) }) {
                            Image.theme(\.increaseTextSize)
                                .padding(.Space.s)
                        }
                    }

                    if configuration.appSupportsDarkMode {
                        Button(action: { store.send(.didTapToggleDarkMode) }) {
                            Image.theme(\.toggleDarkMode)
                                .padding(.Space.s)
                        }
                    }

                    Button(action: { store.send(.didTapToggleFullScreen) }) {
                        Image.theme(state.isFullScreen ? \.exitFullScreen : \.enterFullScreen)
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
            .environment(\.colorScheme, state.appIsInDarkMode ? .light : .dark)
        }
    }
}
