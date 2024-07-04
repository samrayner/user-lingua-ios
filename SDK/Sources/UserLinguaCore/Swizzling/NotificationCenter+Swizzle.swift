// NotificationCenter+Swizzle.swift

import UIKit
import Utilities

extension NotificationCenter {
    static func swizzle() {
        swizzle(
            original: #selector(post(name:object:userInfo:)),
            with: #selector(unswizzledPost(name:object:userInfo:))
        )
    }

    static func unswizzle() {
        swizzle(
            original: #selector(unswizzledPost(name:object:userInfo:)),
            with: #selector(post(name:object:userInfo:))
        )
    }

    // After swizzling, unswizzled... will refer to the original implementation
    // and the original method name will call the below implementation.
    @objc
    func unswizzledPost(name: Notification.Name, object: Any?, userInfo: [AnyHashable: Any]?) {
        let keyboardNotificationNames = [
            UIResponder.keyboardWillChangeFrameNotification,
            UIResponder.keyboardDidChangeFrameNotification,
            UIResponder.keyboardWillHideNotification,
            UIResponder.keyboardWillShowNotification,
            UIResponder.keyboardDidHideNotification,
            UIResponder.keyboardDidShowNotification
        ]

        if keyboardNotificationNames.contains(name) {
            unswizzledPost(name: .swizzled(name), object: object, userInfo: userInfo)
            return
        }

        unswizzledPost(name: name, object: object, userInfo: userInfo)
    }
}
