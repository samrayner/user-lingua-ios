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
        UIView.swizzleAll()
        UITraitCollection.swizzle()
        NotificationCenter.swizzle()
    }

    func unswizzleForForeground() {
        UIView.unswizzleAll()
        UITraitCollection.unswizzle()
        NotificationCenter.unswizzle()
    }

    func swizzleForBackground() {
        Bundle.swizzle()
        UILabel.swizzle()
        UIButton.swizzle()
    }

    func unswizzleForBackground() {
        Bundle.unswizzle()
        UILabel.unswizzle()
        UIButton.unswizzle()
    }
}
