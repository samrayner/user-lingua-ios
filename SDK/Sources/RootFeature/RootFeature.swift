// RootFeature.swift

import CasePaths
import Combine
import CombineFeedback
import Core
import Dependencies
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
        let swizzler: any SwizzlerProtocol

        let selection: SelectionFeature.Dependencies
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

        var isVisible: Bool {
            selection != nil
        }

        var isRecording: Bool {
            self == .recording
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
        // .printChanges()
    }

    package static var feedback: FeedbackOf<Self> {
        .combine(
            SelectionFeature.feedback.pullback(
                state: /State.visible,
                event: /Event.selection,
                dependencies: \.selection
            ),
            // all root state changes go through .recording so this
            // prevents firing when SelectionFeature.State changes
            // but captures all state transitions otherwise
            .state(ifChanged: \.isRecording) { _, new, dependencies in
                switch new {
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

extension RootFeature.Dependencies {
    package init(dependencies: AllDependencies) {
        self.notificationCenter = dependencies.notificationCenter
        self.windowService = dependencies.windowService
        self.swizzler = dependencies.swizzler

        self.selection = .init(dependencies: dependencies)
    }
}
