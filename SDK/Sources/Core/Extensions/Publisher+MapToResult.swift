// Publisher+MapToResult.swift

import Combine
import Foundation

extension Publisher {
    package func mapToResult() -> AnyPublisher<Result<Output, Failure>, Never> {
        map(Result.success)
            .catch { error in
                Just(Result.failure(error))
            }
            .eraseToAnyPublisher()
    }
}
