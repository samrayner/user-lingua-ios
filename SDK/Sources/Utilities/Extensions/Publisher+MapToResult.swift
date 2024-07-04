// Publisher+MapToResult.swift

import Combine
import Foundation

extension Publisher {
    public func mapToResult() -> AnyPublisher<Result<Output, Failure>, Never> {
        map(Result.success)
            .catch { error in
                Just(Result.failure(error))
            }
            .eraseToAnyPublisher()
    }
}
