// Swizzler.swift

import Foundation
import Spyable
import UIKit

@Spyable
protocol SwizzlerProtocol {
    func swizzle()
    func unswizzle()
}

struct Swizzler: SwizzlerProtocol {
    func swizzle() {
        Bundle.swizzle()
        UILabel.swizzle()
        UIButton.swizzle()
    }

    func unswizzle() {
        Bundle.unswizzle()
        UILabel.unswizzle()
        UIButton.unswizzle()
    }
}
