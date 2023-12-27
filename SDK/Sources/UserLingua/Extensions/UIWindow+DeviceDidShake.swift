// UIWindow+DeviceDidShake.swift

import UIKit

extension UIWindow {
    override open func motionEnded(_ motion: UIEvent.EventSubtype, with _: UIEvent?) {
        guard motion == .motionShake else { return }
        NotificationCenter.default.post(name: .deviceDidShake, object: nil)
    }
}
