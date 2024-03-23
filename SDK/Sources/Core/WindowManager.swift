// WindowManager.swift

import Dependencies
import SwiftUI
import UIKit

package protocol WindowManagerProtocol {
    var appWindow: UIWindow? { get }
    func setRootView(_: some View)
    func showWindow()
    func hideWindow()
}

package final class WindowManager: WindowManagerProtocol {
    package init() {}

    package var appWindow: UIWindow?

    private let userLinguaWindow: UIWindow = {
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

    package func showWindow() {
        if appWindow == nil {
            let windows = UIApplication.shared.windowScene?.windows
            appWindow = windows?.first(where: \.isKeyWindow) ?? windows?.first(where: \.isOpaque)
        }
        userLinguaWindow.windowScene = UIApplication.shared.windowScene
        userLinguaWindow.makeKeyAndVisible()
    }

    package func hideWindow() {
        appWindow?.makeKeyAndVisible()
        appWindow = nil
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
    var appWindow: UIWindow?
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
}

package enum WindowManagerDependency: DependencyKey {
    package static let liveValue: any WindowManagerProtocol = WindowManager()
    package static let previewValue: any WindowManagerProtocol = WindowManagerProtocolSpy()
    package static let testValue: any WindowManagerProtocol = WindowManagerProtocolSpy()
}
