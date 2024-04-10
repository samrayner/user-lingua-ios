// NotificationManager.swift

import Combine
import Dependencies
import Foundation
import Spyable

@Spyable
package protocol NotificationManagerProtocol {
    func observe(name: Notification.Name) async -> AsyncStream<Notification>
    func observe(names: [Notification.Name]) async -> AsyncStream<Notification>
}

struct NotificationManager: NotificationManagerProtocol {
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

package enum NotificationManagerDependency: DependencyKey {
    package static let liveValue: any NotificationManagerProtocol = NotificationManager()
    package static let previewValue: any NotificationManagerProtocol = NotificationManagerProtocolSpy()
    package static let testValue: any NotificationManagerProtocol = NotificationManagerProtocolSpy()
}
