// RootFeature.swift

import ComposableArchitecture
import Core
import Foundation
import InspectionFeature
import RecognitionFeature
import SelectionFeature
import SwiftUI
import Theme

@Reducer
public struct RootFeature {
    @Dependency(WindowServiceDependency.self) var windowService
    @Dependency(NotificationServiceDependency.self) var notificationService

    let onForeground: () -> Void
    let onBackground: () -> Void

    public init(
        onForeground: @escaping () -> Void = {},
        onBackground: @escaping () -> Void = {}
    ) {
        self.onForeground = onForeground
        self.onBackground = onBackground
    }

    @Reducer(state: .equatable)
    public enum Mode {
        case disabled
        case recording
        case visible(SelectionFeature)
    }

    @ObservableState
    public struct State: Equatable {
        @Shared(InMemoryKey.configuration) public var configuration = .init()
        public var mode: Mode.State = .disabled

        public init() {}
    }

    public enum Action {
        case enable
        case disable
        case configure(Configuration)
        case didShake
        case mode(Mode.Action)
    }

    enum CancelID {
        case deviceShakeObservation
    }

    public var body: some ReducerOf<Self> {
        Scope(state: \.mode, action: \.mode) {
            EmptyReducer()
                .ifCaseLet(\.visible, action: \.visible) {
                    SelectionFeature()
                }
        }

        Reduce { state, action in
            switch action {
            case .enable:
                state.mode = .recording
                return .run { send in
                    for await _ in await notificationService.observe(name: .deviceDidShake) {
                        await send(.didShake)
                    }
                }
                .cancellable(id: CancelID.deviceShakeObservation)
            case .disable:
                state.mode = .disabled
                return .cancel(id: CancelID.deviceShakeObservation)
            case let .configure(configuration):
                state.configuration = configuration
                return .none
            case .didShake:
                guard state.mode == .recording else { return .none }
                windowService.showWindow()
                state.mode = .visible(.init())
                onForeground()
                return .none
            case .mode(.visible(.delegate(.dismiss))):
                state.mode = .recording
                onBackground()
                windowService.hideWindow()
                return .none
            case .mode:
                return .none
            }
        }
    }
}

public struct RootFeatureView: View {
    let store: StoreOf<RootFeature>

    public init(store: StoreOf<RootFeature>) {
        self.store = store
    }

    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                if let store = store.scope(state: \.mode.visible, action: \.mode.visible) {
                    SelectionFeatureView(store: store)
                }
            }
            .foregroundColor(.theme(\.text))
            .tint(.theme(\.tint))
        }
    }
}
