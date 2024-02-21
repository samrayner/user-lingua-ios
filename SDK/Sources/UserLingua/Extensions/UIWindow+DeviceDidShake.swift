// UIWindow+DeviceDidShake.swift

import UIKit

extension UIWindow {
    // swiftlint:disable:next override_in_extension
    override open func motionEnded(_ motion: UIEvent.EventSubtype, with _: UIEvent?) {
        guard motion == .motionShake else { return }
        NotificationCenter.default.post(name: .deviceDidShake, object: nil)
    }
}
