// WindowManager.swift

import Dependencies
import SwiftUI
import UIKit

package protocol WindowManagerProtocol {
    var userLinguaWindow: UIWindow { get }
    var appUIStyle: UIUserInterfaceStyle { get }
    func setRootView(_: some View)
    func screenshotAppWindow() -> UIImage?
    func showWindow()
    func resetAppWindow()
    func hideWindow()
    func toggleDarkMode()
    func translateApp(focusing: CGPoint, in: CGRect, animationDuration: TimeInterval)
}

package final class WindowManager: WindowManagerProtocol {
    package init() {}

    var appWindow: UIWindow?
    var originalAppWindowUIStyleOverride: UIUserInterfaceStyle = .unspecified

    package var appUIStyle: UIUserInterfaceStyle {
        if originalAppWindowUIStyleOverride == .unspecified {
            UIScreen.main.traitCollection.userInterfaceStyle
        } else {
            originalAppWindowUIStyleOverride
        }
    }

    package let userLinguaWindow: UIWindow = {
        let window = UIApplication.shared.windowScene.map(UIWindow.init) ?? UIWindow(frame: UIScreen.main.bounds)
        window.isHidden = true
        window.backgroundColor = .clear
        window.windowLevel = .statusBar
        return window
    }()

    package func setRootView(_ rootView: some View) {
        userLinguaWindow.rootViewController = UIHostingController(rootView: rootView)
        userLinguaWindow.rootViewController?.view.backgroundColor = .clear
    }

    private func screenshot(window: UIWindow) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(
            window.layer.frame.size,
            false,
            UIScreen.main.scale
        )

        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        window.layer.render(in: context)
        let screenshot = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return screenshot
    }

    package func screenshotAppWindow() -> UIImage? {
        appWindow.flatMap(screenshot)
    }

    package func showWindow() {
        if appWindow == nil {
            let windows = UIApplication.shared.windowScene?.windows
            appWindow = windows?.first(where: \.isKeyWindow) ?? windows?.first(where: \.isOpaque)
        }
        UIApplication.shared.endEditing()

        originalAppWindowUIStyleOverride = appWindow?.overrideUserInterfaceStyle ?? .unspecified
        userLinguaWindow.overrideUserInterfaceStyle = originalAppWindowUIStyleOverride

        userLinguaWindow.windowScene = UIApplication.shared.windowScene
        userLinguaWindow.makeKeyAndVisible()
    }

    package func hideWindow() {
        appWindow?.makeKeyAndVisible()
        appWindow = nil
        originalAppWindowUIStyleOverride = .unspecified
        userLinguaWindow.isHidden = true
    }

    package func resetAppWindow() {
        appWindow?.layer.removeTranslation()
        appWindow?.overrideUserInterfaceStyle = originalAppWindowUIStyleOverride
    }

    package func toggleDarkMode() {
        appWindow?.toggleDarkMode()
    }

    package func translateApp(focusing focalPoint: CGPoint, in viewportFrame: CGRect, animationDuration: TimeInterval = 0) {
        guard let appWindow else { return }

        let maxTranslateUp = viewportFrame.maxY - appWindow.bounds.maxY
        let maxTranslateDown = viewportFrame.minY
        let yOffset = (viewportFrame.midY - focalPoint.y).clamped(to: maxTranslateUp ... maxTranslateDown)

        if animationDuration > 0 {
            let animation = CABasicAnimation(keyPath: "transform.translation.y")
            animation.fromValue = appWindow.layer.translationIn2D.y
            animation.toValue = yOffset
            animation.duration = animationDuration
            appWindow.layer.translate(y: yOffset)
            appWindow.layer.add(animation, forKey: nil)
        } else {
            appWindow.layer.translate(y: yOffset)
        }
    }
}

extension UIApplication {
    fileprivate var windowScene: UIWindowScene? {
        connectedScenes
            .first {
                $0 is UIWindowScene &&
                    $0.activationState == .foregroundActive
            }
            .flatMap { $0 as? UIWindowScene }
    }
}

// Spyable doesn't handle `some View` properly
class WindowManagerProtocolSpy: WindowManagerProtocol {
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

    var toggleDarkModeCallsCount = 0
    var toggleDarkModeCalled: Bool {
        toggleDarkModeCallsCount > 0
    }

    var toggleDarkModeClosure: (() -> Void)?
    func toggleDarkMode() {
        toggleDarkModeCallsCount += 1
        toggleDarkModeClosure?()
    }

    var translateAppFocusingInCallsCount = 0
    var translateAppFocusingInCalled: Bool {
        translateAppFocusingInCallsCount > 0
    }

    var translateAppFocusingInReceivedArguments: (focusing: CGPoint, in: CGRect, animationDuration: TimeInterval)?
    var translateAppFocusingInReceivedInvocations: [(focusing: CGPoint, in: CGRect, animationDuration: TimeInterval)] = []
    var translateAppFocusingInClosure: ((CGPoint, CGRect, TimeInterval) -> Void)?
    func translateApp(focusing: CGPoint, in rect: CGRect, animationDuration: TimeInterval) {
        translateAppFocusingInCallsCount += 1
        translateAppFocusingInReceivedArguments = (focusing, rect, animationDuration)
        translateAppFocusingInReceivedInvocations.append((focusing, rect, animationDuration))
        translateAppFocusingInClosure?(focusing, rect, animationDuration)
    }
}

package enum WindowManagerDependency: DependencyKey {
    package static let liveValue: any WindowManagerProtocol = WindowManager()
    package static let previewValue: any WindowManagerProtocol = WindowManagerProtocolSpy()
    package static let testValue: any WindowManagerProtocol = WindowManagerProtocolSpy()
}
