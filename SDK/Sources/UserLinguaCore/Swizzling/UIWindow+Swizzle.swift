// UIWindow+Swizzle.swift

import Combine
import UIKit

extension UIWindow {
    static func swizzle() {
        swizzle(
            original: #selector(motionEnded),
            with: #selector(unswizzledMotionEnded)
        )
    }

    static func unswizzle() {
        swizzle(
            original: #selector(unswizzledMotionEnded),
            with: #selector(motionEnded)
        )
    }

    @objc
    open func unswizzledMotionEnded(_ motion: UIEvent.EventSubtype, with _: UIEvent?) {
        // unswizzledMotionEnded(motion, with: event)
        guard motion == .motionShake else { return }
        NotificationCenter.default.post(name: .deviceDidShake, object: nil)
    }
}
