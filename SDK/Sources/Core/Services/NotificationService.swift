// NotificationService.swift

import Combine
import Foundation

// sourcery: AutoMockable
package protocol NotificationServiceProtocol {
    func observe(name: Notification.Name) async -> AsyncStream<Notification>
    func observe(names: [Notification.Name]) async -> AsyncStream<Notification>
}

struct NotificationService: NotificationServiceProtocol {
    func observe(name: Notification.Name) async -> AsyncStream<Notification> {
        NotificationCenter.default
            .notifications(named: name)
            .eraseToStream()
    }

    func observe(names: [Notification.Name]) async -> AsyncStream<Notification> {
        Publishers.MergeMany(
            names.map { NotificationCenter.default.publisher(for: $0) }
        )
        .values
        .eraseToStream()
    }
}
