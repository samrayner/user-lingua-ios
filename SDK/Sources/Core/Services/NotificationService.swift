// NotificationService.swift

import Combine
import Dependencies
import Foundation

// sourcery: AutoMockable
public protocol NotificationServiceProtocol {
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

public enum NotificationServiceDependency: DependencyKey {
    public static let liveValue: any NotificationServiceProtocol = NotificationService()
    public static let previewValue: any NotificationServiceProtocol = NotificationServiceProtocolMock()
    public static let testValue: any NotificationServiceProtocol = NotificationServiceProtocolMock()
}
