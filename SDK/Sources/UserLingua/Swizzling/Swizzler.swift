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

struct Swizzler: SwizzlerProtocol {
    func swizzleForForeground() {
        UITraitCollection.swizzle()
        NotificationCenter.swizzle()
    }

    func unswizzleForForeground() {
        UITraitCollection.unswizzle()
        NotificationCenter.unswizzle()
    }

    func swizzleForBackground() {
        UIView.swizzleAll()
        Bundle.swizzle()
        UILabel.swizzle()
        UIButton.swizzle()
    }

    func unswizzleForBackground() {
        UIView.unswizzleAll()
        Bundle.unswizzle()
        UILabel.unswizzle()
        UIButton.unswizzle()
    }
}
