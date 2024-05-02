// WindowServiceProtocolSpy.swift

import SwiftUI
import UIKit

// Spyable doesn't handle `some View` properly
class WindowServiceProtocolSpy: WindowServiceProtocol {
    var appYOffset: CGFloat {
        get {
            underlyingAppYOffset
        }
        set {
            underlyingAppYOffset = newValue
        }
    }

    var underlyingAppYOffset: CGFloat!

    var userLinguaWindow: UIWindow {
        get {
            underlyingUserLinguaWindow
        }
        set {
            underlyingUserLinguaWindow = newValue
        }
    }

    var underlyingUserLinguaWindow: UIWindow!

    var appUIStyle: UIUserInterfaceStyle {
        get {
            underlyingAppUIStyle
        }
        set {
            underlyingAppUIStyle = newValue
        }
    }

    var underlyingAppUIStyle: UIUserInterfaceStyle!
    var setRootViewCallsCount = 0
    var setRootViewCalled: Bool {
        setRootViewCallsCount > 0
    }

    var setRootViewReceived: (any View)?
    var setRootViewReceivedInvocations: [any View] = []
    var setRootViewClosure: ((any View) -> Void)?
    func setRootView(_ rootView: some View) {
        setRootViewCallsCount += 1
        setRootViewReceived = rootView
        setRootViewReceivedInvocations.append(rootView)
        setRootViewClosure?(rootView)
    }

    var screenshotAppWindowCallsCount = 0
    var screenshotAppWindowCalled: Bool {
        screenshotAppWindowCallsCount > 0
    }

    var screenshotAppWindowReturnValue: UIImage?
    var screenshotAppWindowClosure: (() -> UIImage?)?
    func screenshotAppWindow() -> UIImage? {
        screenshotAppWindowCallsCount += 1
        if screenshotAppWindowClosure != nil {
            return screenshotAppWindowClosure!()
        } else {
            return screenshotAppWindowReturnValue
        }
    }

    var showWindowCallsCount = 0
    var showWindowCalled: Bool {
        showWindowCallsCount > 0
    }

    var showWindowClosure: (() -> Void)?
    func showWindow() {
        showWindowCallsCount += 1
        showWindowClosure?()
    }

    var hideWindowCallsCount = 0
    var hideWindowCalled: Bool {
        hideWindowCallsCount > 0
    }

    var hideWindowClosure: (() -> Void)?
    func hideWindow() {
        hideWindowCallsCount += 1
        hideWindowClosure?()
    }

    var resetAppWindowCallsCount = 0
    var resetAppWindowCalled: Bool {
        resetAppWindowCallsCount > 0
    }

    var resetAppWindowClosure: (() -> Void)?
    func resetAppWindow() {
        resetAppWindowCallsCount += 1
        resetAppWindowClosure?()
    }

    var resetAppPositionCallsCount = 0
    var resetAppPositionCalled: Bool {
        resetAppWindowCallsCount > 0
    }

    var resetAppPositionClosure: (() -> Void)?
    func resetAppPosition() {
        resetAppPositionCallsCount += 1
        resetAppPositionClosure?()
    }

    var toggleDarkModeCallsCount = 0
    var toggleDarkModeCalled: Bool {
        toggleDarkModeCallsCount > 0
    }

    var toggleDarkModeClosure: (() -> Void)?
    func toggleDarkMode() {
        toggleDarkModeCallsCount += 1
        toggleDarkModeClosure?()
    }

    var positionAppFocusingInAnimationDurationCallsCount = 0
    var positionAppFocusingInAnimationDurationCalled: Bool {
        positionAppFocusingInAnimationDurationCallsCount > 0
    }

    var positionAppFocusingInAnimationDurationReceivedArguments: (focusing: CGPoint, frame: CGRect, animationDuration: TimeInterval)?
    var positionAppFocusingInAnimationDurationReceivedInvocations: [(focusing: CGPoint, frame: CGRect, animationDuration: TimeInterval)] =
        []
    var positionAppFocusingInAnimationDurationClosure: ((CGPoint, CGRect, TimeInterval) -> Void)?
    func positionApp(focusing: CGPoint, in frame: CGRect, animationDuration: TimeInterval) {
        positionAppFocusingInAnimationDurationCallsCount += 1
        positionAppFocusingInAnimationDurationReceivedArguments = (focusing, frame, animationDuration)
        positionAppFocusingInAnimationDurationReceivedInvocations.append((focusing, frame, animationDuration))
        positionAppFocusingInAnimationDurationClosure?(focusing, frame, animationDuration)
    }

    var positionAppYOffsetAnimationDurationCallsCount = 0
    var positionAppYOffsetAnimationDurationCalled: Bool {
        positionAppYOffsetAnimationDurationCallsCount > 0
    }

    var positionAppYOffsetAnimationDurationReceivedArguments: (yOffset: CGFloat, animationDuration: TimeInterval)?
    var positionAppYOffsetAnimationDurationReceivedInvocations: [(yOffset: CGFloat, animationDuration: TimeInterval)] = []
    var positionAppYOffsetAnimationDurationClosure: ((CGFloat, TimeInterval) -> Void)?
    func positionApp(yOffset: CGFloat, animationDuration: TimeInterval) {
        positionAppYOffsetAnimationDurationCallsCount += 1
        positionAppYOffsetAnimationDurationReceivedArguments = (yOffset, animationDuration)
        positionAppYOffsetAnimationDurationReceivedInvocations.append((yOffset, animationDuration))
        positionAppYOffsetAnimationDurationClosure?(yOffset, animationDuration)
    }
}
