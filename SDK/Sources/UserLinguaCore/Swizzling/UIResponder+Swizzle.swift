// UIResponder+Swizzle.swift

import Combine
import UIKit

extension UIResponder {
    static func swizzleUIResponder() {
        swizzle(
            original: #selector(motionEnded),
            with: #selector(unswizzledMotionEnded)
        )
    }

    static func unswizzleUIResponder() {
        swizzle(
            original: #selector(unswizzledMotionEnded),
            with: #selector(motionEnded)
        )
    }

    @objc
    open func unswizzledMotionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        unswizzledMotionEnded(motion, with: event)
        guard motion == .motionShake else { return }
        NotificationCenter.default.post(name: .deviceDidShake, object: nil)
    }
}
