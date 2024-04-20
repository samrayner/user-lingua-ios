// WindowManager.swift

import Dependencies
import SwiftUI
import UIKit

package protocol WindowManagerProtocol {
    var userLinguaWindow: UIWindow { get }
    func setRootView(_: some View)
    func screenshotAppWindow() -> UIImage?
    func showWindow()
    func hideWindow()
    func toggleDarkMode()
    func translateApp(focusing: CGPoint, in: CGRect, animationDuration: TimeInterval)
}

package final class WindowManager: WindowManagerProtocol {
    package init() {}

    var appWindow: UIWindow?
    var originalAppWindowUIStyleOverride: UIUserInterfaceStyle = .unspecified

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
        appWindow?.layer.transform = CATransform3DTranslate(CATransform3DIdentity, 0, 0, 0)
        appWindow?.overrideUserInterfaceStyle = originalAppWindowUIStyleOverride
        appWindow?.makeKeyAndVisible()
        appWindow = nil
        originalAppWindowUIStyleOverride = .unspecified
        userLinguaWindow.isHidden = true
    }

    package func toggleDarkMode() {
        appWindow?.toggleDarkMode()
    }

    package func translateApp(focusing focalPoint: CGPoint, in viewportFrame: CGRect, animationDuration: TimeInterval = 0) {
        guard let appWindow else { return }

        let maxTranslateUp = viewportFrame.maxY - appWindow.bounds.maxY
        let maxTranslateDown = viewportFrame.minY
        let yOffset = viewportFrame.midY - focalPoint.y
        let boundedYOffset = min(maxTranslateDown, max(maxTranslateUp, yOffset))

        func applyTransform() {
            appWindow.layer.transform = CATransform3DTranslate(CATransform3DIdentity, 0, boundedYOffset, 0)
        }

        if animationDuration > 0 {
            let animation = CABasicAnimation(keyPath: "transform.translation.y")
            // translation matrix is [1 0 0 0; 0 1 0 0; 0 0 1 0; tx TY tz 1]
            animation.fromValue = appWindow.layer.transform.m42
            animation.toValue = boundedYOffset
            animation.duration = animationDuration
            applyTransform()
            appWindow.layer.add(animation, forKey: nil)
        } else {
            applyTransform()
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
