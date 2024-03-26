// NotificationManager.swift

import Dependencies
import Foundation
import Spyable

@Spyable
package protocol NotificationManagerProtocol {
    func observe(_ notificationName: Notification.Name) async -> AsyncStream<Void>
}

struct NotificationManager: NotificationManagerProtocol {
    func observe(_ notificationName: Notification.Name) async -> AsyncStream<Void> {
        AsyncStream(
            NotificationCenter.default
                .notifications(named: notificationName)
                .map { _ in }
        )
    }
}

package enum NotificationManagerDependency: DependencyKey {
    package static let liveValue: any NotificationManagerProtocol = NotificationManager()
    package static let previewValue: any NotificationManagerProtocol = NotificationManagerProtocolSpy()
    package static let testValue: any NotificationManagerProtocol = NotificationManagerProtocolSpy()
}
