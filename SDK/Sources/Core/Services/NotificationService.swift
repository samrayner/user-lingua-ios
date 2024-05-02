// NotificationService.swift

import Combine
import Dependencies
import Foundation
import Spyable

@Spyable
package protocol NotificationServiceProtocol {
    func observe(name: Notification.Name) async -> AsyncStream<Notification>
    func observe(names: [Notification.Name]) async -> AsyncStream<Notification>
}

struct NotificationService: NotificationServiceProtocol {
    func observe(name: Notification.Name) async -> AsyncStream<Notification> {
        AsyncStream(
            NotificationCenter.default
                .notifications(named: name)
        )
    }

    func observe(names: [Notification.Name]) async -> AsyncStream<Notification> {
        AsyncStream(
            Publishers.MergeMany(
                names.map { NotificationCenter.default.publisher(for: $0) }
            )
            .values
        )
    }
}

package enum NotificationServiceDependency: DependencyKey {
    package static let liveValue: any NotificationServiceProtocol = NotificationService()
    package static let previewValue: any NotificationServiceProtocol = NotificationServiceProtocolSpy()
    package static let testValue: any NotificationServiceProtocol = NotificationServiceProtocolSpy()
}
