// Generated using Sourcery — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// swiftlint:disable line_length
// swiftlint:disable variable_name

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif
























class SwizzlerProtocolMock: SwizzlerProtocol {




    //MARK: - swizzleForForeground

    var swizzleForForegroundVoidCallsCount = 0
    var swizzleForForegroundVoidCalled: Bool {
        return swizzleForForegroundVoidCallsCount > 0
    }
    var swizzleForForegroundVoidClosure: (() -> Void)?

    func swizzleForForeground() {
        swizzleForForegroundVoidCallsCount += 1
        swizzleForForegroundVoidClosure?()
    }

    //MARK: - unswizzleForForeground

    var unswizzleForForegroundVoidCallsCount = 0
    var unswizzleForForegroundVoidCalled: Bool {
        return unswizzleForForegroundVoidCallsCount > 0
    }
    var unswizzleForForegroundVoidClosure: (() -> Void)?

    func unswizzleForForeground() {
        unswizzleForForegroundVoidCallsCount += 1
        unswizzleForForegroundVoidClosure?()
    }

    //MARK: - swizzleForBackground

    var swizzleForBackgroundVoidCallsCount = 0
    var swizzleForBackgroundVoidCalled: Bool {
        return swizzleForBackgroundVoidCallsCount > 0
    }
    var swizzleForBackgroundVoidClosure: (() -> Void)?

    func swizzleForBackground() {
        swizzleForBackgroundVoidCallsCount += 1
        swizzleForBackgroundVoidClosure?()
    }

    //MARK: - unswizzleForBackground

    var unswizzleForBackgroundVoidCallsCount = 0
    var unswizzleForBackgroundVoidCalled: Bool {
        return unswizzleForBackgroundVoidCallsCount > 0
    }
    var unswizzleForBackgroundVoidClosure: (() -> Void)?

    func unswizzleForBackground() {
        unswizzleForBackgroundVoidCallsCount += 1
        unswizzleForBackgroundVoidClosure?()
    }


}
