// Swizzler.swift

import Foundation
import Services
import UIKit

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
        UIView.swizzleUIView()
        Bundle.swizzleBundle()
        UILabel.swizzleUILabel()
        UIButton.swizzleUIButton()
        UIResponder.swizzleUIResponder()
    }

    func unswizzleForBackground() {
        guard isSwizzledForBackground else { return }
        defer { isSwizzledForBackground = false }
        UIView.unswizzleUIView()
        Bundle.unswizzleBundle()
        UILabel.unswizzleUILabel()
        UIButton.unswizzleUIButton()
        UIResponder.unswizzleUIResponder()
    }
}
