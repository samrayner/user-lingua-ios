// EffectActions.swift

extension Effect {
    @_spi(Internals) public var actions: AsyncStream<Action> {
        switch operation {
        case .none:
            .finished
        case let .publisher(publisher):
            AsyncStream { continuation in
                let cancellable = publisher.sink(
                    receiveCompletion: { _ in continuation.finish() },
                    receiveValue: { continuation.yield($0) }
                )
                continuation.onTermination = { _ in
                    cancellable.cancel()
                }
            }
        case let .run(priority, operation):
            AsyncStream { continuation in
                let task = Task(priority: priority) {
                    await operation(Send { action in continuation.yield(action) })
                    continuation.finish()
                }
                continuation.onTermination = { _ in task.cancel() }
            }
        }
    }
}
