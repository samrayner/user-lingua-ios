// VisualPreviewFeature.swift

import ComposableArchitecture
import Core
import Foundation
import SwiftUI
import Theme

@Reducer
package struct VisualPreviewFeature {
    @Dependency(ContentSizeCategoryServiceDependency.self) var contentSizeCategoryService
    @Dependency(WindowServiceDependency.self) var windowService

    @ObservableState
    package struct State: Equatable {
        @Shared(Configuration.persistenceKey) var configuration = .init()
        @Shared private(set) var isFullScreen: Bool
    }

    package enum Action {
        case didTapIncreaseTextSize
        case didTapDecreaseTextSize
        case didTapToggleDarkMode
        case delegate(Delegate)
    }

    @CasePathable
    package enum Delegate {
        case didTapToggleFullScreen
    }

    package var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .didTapIncreaseTextSize:
                contentSizeCategoryService.incrementAppContentSizeCategory()
                return .none
            case .didTapDecreaseTextSize:
                contentSizeCategoryService.decrementAppContentSizeCategory()
                return .none
            case .didTapToggleDarkMode:
                windowService.toggleDarkMode()
                return .none
            case .delegate:
                return .none
            }
        }
    }
}

struct VisualPreviewFeatureView: View {
    private let store: StoreOf<VisualPreviewFeature>
    @State private var isInDarkMode: Bool

    init(
        store: StoreOf<VisualPreviewFeature>,
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

                    Button(action: { store.send(.delegate(.didTapToggleFullScreen)) }) {
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
