// NotificationName+UserLingua.swift

import Foundation

extension Notification.Name {
    package static let deviceDidShake = Self("deviceDidShake")

    package static func swizzled(_ name: Self) -> Self {
        .init("UserLingua_\(name.rawValue)")
    }
}
