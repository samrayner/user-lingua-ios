// Reducer.swift

import CasePaths
import CustomDump

public struct Reducer<State, Event> {
    public let reduce: (inout State, Event) -> Void

    public init(reduce: @escaping (inout State, Event) -> Void) {
        self.reduce = reduce
    }

    public func callAsFunction(_ state: inout State, _ event: Event) {
        reduce(&state, event)
    }

    public static func combine(_ reducers: Reducer...) -> Reducer {
        .init { state, event in
            for reducer in reducers {
                reducer(&state, event)
            }
        }
    }

    public func pullback<GlobalState, GlobalEvent>(
        state stateKeyPath: WritableKeyPath<GlobalState, State>,
        event eventCasePath: CasePath<GlobalEvent, Event>
    ) -> Reducer<GlobalState, GlobalEvent> {
        .init { globalState, globalEvent in
            guard let localAction = eventCasePath.extract(from: globalEvent) else {
                return
            }
            self(&globalState[keyPath: stateKeyPath], localAction)
        }
    }

    /*
     enum AppState {
      case authenticated(AuthenticatedState)
      case nonAuth(NonOutState)
     }

     enum AppEvent {
      case authenticated(AuthenticatedEvent)
      case nonAuth(NonOutEvent)
     }
     */
    public func pullback<GlobalState, GlobalEvent>(
        state stateCasePath: CasePath<GlobalState, State>,
        event eventCasePath: CasePath<GlobalEvent, Event>
    ) -> Reducer<GlobalState, GlobalEvent> {
        .init { globalState, globalEvent in
            guard let localEvent = eventCasePath.extract(from: globalEvent) else { return }
            guard var localState = stateCasePath.extract(from: globalState) else { return }
            reduce(&localState, localEvent)
            globalState = stateCasePath.embed(localState)
        }
    }

    public func optional() -> Reducer<State?, Event> {
        .init { state, event in
            if state == nil {
                return
            }
            reduce(&state!, event)
        }
    }

    public func printChanges(
        printer: @escaping (String) -> Void = { print($0) }
    ) -> Reducer {
        .init { state, event in
            let oldState = state

            self(&state, event)

            var target = ""
            target.write("received event:\n")
            CustomDump.customDump(event, to: &target, indent: 2)
            target.write("\n")
            target.write(diff(oldState, state).map { "\($0)\n" } ?? "  (No state changes)\n")
            printer(target)
        }
    }
}

public typealias ReducerOf<F: Feature> = Reducer<F.State, F.Event>
