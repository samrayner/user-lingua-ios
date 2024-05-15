// NotificationName+UserLingua.swift

import Foundation

extension Notification.Name {
    public static var deviceDidShake: Self { .init(#function) }

    public static func swizzled(_ name: Self) -> Self {
        .init("UserLingua_\(name.rawValue)")
    }
}
