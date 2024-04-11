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
        NotificationCenter.swizzle()
    }

    func unswizzleForForeground() {
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
