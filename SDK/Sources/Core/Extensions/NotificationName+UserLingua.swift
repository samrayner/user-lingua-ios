// NotificationName+UserLingua.swift

import Foundation

extension Notification.Name {
    package static var deviceDidShake: Self { .init(#function) }

    package static func swizzled(_ name: Self) -> Self {
        .init("UserLingua_\(name.rawValue)")
    }
}
