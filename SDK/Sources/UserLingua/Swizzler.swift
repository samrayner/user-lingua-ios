// Swizzler.swift

import Dependencies
import Foundation
import Spyable
import UIKit

@Spyable
protocol SizzlerProtocol {
    func swizzle()
    func unswizzle()
}

final class Swizzler: SizzlerProtocol {
    init() {}

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

enum SwizzlerDependency: DependencyKey {
    static let liveValue: any SizzlerProtocol = Swizzler()
    static let previewValue: any SizzlerProtocol = SizzlerProtocolSpy()
    static let testValue: any SizzlerProtocol = SizzlerProtocolSpy()
}
