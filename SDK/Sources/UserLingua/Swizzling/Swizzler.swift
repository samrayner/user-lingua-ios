// Swizzler.swift

import Foundation
import Spyable
import UIKit

@Spyable
protocol SwizzlerProtocol {
    func swizzleForForeground()
    func unswizzleForForeground()
    func swizzleForBackground()
    func unswizzleForBackground()
}

final class Swizzler: SwizzlerProtocol {
    private var isSwizzledForForeground = false
    private var isSwizzledForBackground = false

    func swizzleForForeground() {
        guard !isSwizzledForForeground else { return }
        defer { isSwizzledForForeground = true }
        UITraitCollection.swizzle()
        NotificationCenter.swizzle()
    }

    func unswizzleForForeground() {
        guard isSwizzledForForeground else { return }
        defer { isSwizzledForForeground = false }
        UITraitCollection.unswizzle()
        NotificationCenter.unswizzle()
    }

    func swizzleForBackground() {
        guard !isSwizzledForBackground else { return }
        defer { isSwizzledForBackground = true }
        UIView.swizzleAll()
        Bundle.swizzle()
        UILabel.swizzle()
        UIButton.swizzle()
    }

    func unswizzleForBackground() {
        guard isSwizzledForBackground else { return }
        defer { isSwizzledForBackground = false }
        UIView.unswizzleAll()
        Bundle.unswizzle()
        UILabel.unswizzle()
        UIButton.unswizzle()
    }
}
