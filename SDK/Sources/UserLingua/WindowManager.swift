// WindowManager.swift

import Dependencies
import SwiftUI
import UIKit

protocol WindowManagerProtocol {
    func screenshotAppWindow() -> UIImage?
    func showWindow(rootView: some View)
    func hideWindow()
}

final class WindowManager: WindowManagerProtocol {
    init() {}

    private let userLinguaWindow: UIWindow = {
        let window = UIApplication.shared.windowScene.map(UIWindow.init) ?? UIWindow(frame: UIScreen.main.bounds)
        window.isHidden = true
        window.backgroundColor = .clear
        window.rootViewController?.view.backgroundColor = .clear
        window.windowLevel = .statusBar
        return window
    }()

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

    func screenshotAppWindow() -> UIImage? {
        appWindow().flatMap(screenshot)
    }

    private func appWindow() -> UIWindow? {
        let windows = UIApplication.shared.windowScene?.windows.filter { $0 != userLinguaWindow }
        return windows?.first(where: \.isKeyWindow) ?? windows?.last
    }

    func showWindow(rootView: some View) {
        userLinguaWindow.windowScene = UIApplication.shared.windowScene
        userLinguaWindow.rootViewController = UIHostingController(rootView: rootView)
        userLinguaWindow.makeKeyAndVisible()
    }

    func hideWindow() {
        appWindow()?.makeKeyAndVisible()
        userLinguaWindow.isHidden = true
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

    var showWindowRootViewCallsCount = 0
    var showWindowRootViewCalled: Bool {
        showWindowRootViewCallsCount > 0
    }

    var showWindowRootViewReceivedRootView: (any View)?
    var showWindowRootViewReceivedInvocations: [any View] = []
    var showWindowRootViewClosure: ((any View) -> Void)?
    func showWindow(rootView: some View) {
        showWindowRootViewCallsCount += 1
        showWindowRootViewReceivedRootView = rootView
        showWindowRootViewReceivedInvocations.append(rootView)
        showWindowRootViewClosure?(rootView)
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
}

enum WindowManagerDependency: DependencyKey {
    static let liveValue: any WindowManagerProtocol = WindowManager()
    static let previewValue: any WindowManagerProtocol = WindowManagerProtocolSpy()
    static let testValue: any WindowManagerProtocol = WindowManagerProtocolSpy()
}
