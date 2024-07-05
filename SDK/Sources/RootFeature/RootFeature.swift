// RootFeature.swift

import CasePaths
import Combine
import CombineFeedback
import Dependencies
import Foundation
import InspectionFeature
import Models
import RecognitionFeature
import SelectionFeature
import SwiftUI
import Theme
import Utilities

public enum RootFeature: Feature {
    public struct Dependencies: Scoped {
        public typealias Parent = AllDependencies

        let notificationCenter: NotificationCenter
        let windowService: any WindowServiceProtocol
        let swizzler: any SwizzlerProtocol

        // sourcery: initFromParent
        let selection: SelectionFeature.Dependencies
    }

    public enum State: Equatable {
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

        var isVisible: Bool {
            selection != nil
        }

        var isRecording: Bool {
            self == .recording
        }
    }

    public enum Event {
        case enable
        case disable
        case show
        case didShake
        case selection(SelectionFeature.Event)
    }

    public static func reducer() -> ReducerOf<Self> {
        .combine(
            SelectionFeature.reducer()
                .pullback(state: /State.visible, event: /Event.selection),

            ReducerOf<Self> { state, event in
                switch event {
                case .enable:
                    state = .recording
                case .disable:
                    state = .disabled
                case .show:
                    guard state.isRecording else { return }
                    state = .visible(.init())
                case .selection(.delegate(.dismiss)):
                    state = .recording
                case .selection, .didShake:
                    return
                }
            }
        )
        // .printChanges()
    }

    public static var feedback: FeedbackOf<Self> {
        .combine(
            SelectionFeature.feedback.pullback(
                state: /State.visible,
                event: /Event.selection,
                dependencies: \.selection
            ),
            // all root state changes go through .recording so this
            // prevents firing when SelectionFeature.State changes
            // but captures all state transitions otherwise
            .state(ifChanged: \.isRecording) { state, dependencies in
                switch state.new {
                case .recording:
                    dependencies.swizzler.unswizzleForForeground()
                    dependencies.windowService.hideWindow()
                    return .publish(
                        dependencies.notificationCenter
                            .publisher(for: .deviceDidShake)
                            .map { _ in .didShake }
                            .eraseToAnyPublisher()
                    )
                case .visible:
                    dependencies.windowService.showWindow()
                    dependencies.swizzler.swizzleForForeground()
                    return .none
                case .disabled:
                    return .none
                }
            },
            .event(/Event.didShake) { _, state, _ in
                if state.old.isRecording {
                    .send(.show)
                } else {
                    .none
                }
            }
        )
    }
}

public struct RootFeatureView: View {
    typealias Event = RootFeature.Event

    let store: StoreOf<RootFeature>

    public init(store: StoreOf<RootFeature>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store, scoped: \.isVisible) { _ in
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
