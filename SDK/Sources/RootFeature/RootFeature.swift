// RootFeature.swift

import CasePaths
import CombineFeedback
import Core
import Foundation
import InspectionFeature
import RecognitionFeature
import SelectionFeature
import SwiftUI
import Theme

package enum RootFeature: Feature {
    package struct Dependencies {
        let notificationCenter: NotificationCenter
        let windowService: any WindowServiceProtocol
        let onForeground: () -> Void
        let onBackground: () -> Void

        package init(
            notificationCenter: NotificationCenter,
            windowService: any WindowServiceProtocol,
            onForeground: @escaping () -> Void,
            onBackground: @escaping () -> Void
        ) {
            self.notificationCenter = notificationCenter
            self.windowService = windowService
            self.onForeground = onForeground
            self.onBackground = onBackground
        }
    }

    package enum State: Equatable {
        case disabled
        case recording
        case visible(SelectionFeature.State)

        var selection: SelectionFeature.State? {
            switch self {
            case let .visible(state):
                state
            case .disabled, .recording:
                nil
            }
        }
    }

    package enum Event {
        case enable
        case disable
        case didShake
        case selection(SelectionFeature.Event)
    }

    package static func reducer() -> ReducerOf<Self> {
        .combine(
            SelectionFeature.reducer()
                .pullback(state: /State.visible, event: /Event.selection),

            ReducerOf<Self> { state, event in
                switch event {
                case .enable:
                    state = .recording
                case .disable:
                    state = .disabled
                case .didShake:
                    guard state == .recording else { return }
                    state = .visible(.init())
                case .selection(.delegate(.dismiss)):
                    state = .recording
                case .selection:
                    return
                }
            }
        )
    }

    package static func feedback() -> FeedbackOf<Self> {
        .combine(
            .state { state, dependencies in
                switch state {
                case .recording:
                    dependencies.onBackground()
                    dependencies.windowService.hideWindow()
                    return .publish(
                        dependencies.notificationCenter
                            .publisher(for: .deviceDidShake)
                            .map { _ in .didShake }
                            .eraseToAnyPublisher()
                    )
                case .visible:
                    dependencies.windowService.showWindow()
                    dependencies.onForeground()
                    return .none
                case .disabled:
                    return .none
                }
            }
        )
    }
}

package struct RootFeatureView: View {
    typealias Event = RootFeature.Event

    let store: StoreOf<RootFeature>

    package init(store: StoreOf<RootFeature>) {
        self.store = store
    }

    package var body: some View {
        WithViewStore(store) { _ in
            ZStack {
                if let store = store.scoped(to: \.selection, event: Event.selection) {
                    SelectionFeatureView(store: store)
                }
            }
            .foregroundColor(.theme(\.text))
            .tint(.theme(\.tint))
        }
    }
}
