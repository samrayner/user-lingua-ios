// WindowManager.swift

import Dependencies
import Spyable
import SwiftUI
import UIKit

@Spyable
protocol WindowManagerProtocol {
    func screenshotAppWindow() -> UIImage?
    func showWindow()
    func hideWindow()
}

final class WindowManager {
    private let userLinguaWindow: UIWindow

    init(rootView: some View) {
        self.userLinguaWindow = Self.makeWindow(rootView: rootView)
    }

    private static func makeWindow(rootView: some View) -> UIWindow {
        let window = UIApplication.shared.windowScene.map(UIWindow.init) ?? UIWindow(frame: UIScreen.main.bounds)
        window.isHidden = true
        window.backgroundColor = .clear
        window.rootViewController = UIHostingController(rootView: rootView)
        window.rootViewController?.view.backgroundColor = .clear
        window.windowLevel = .statusBar
        return window
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

    func screenshotAppWindow() -> UIImage? {
        appWindow().flatMap(screenshot)
    }

    private func appWindow() -> UIWindow? {
        let windows = UIApplication.shared.windowScene?.windows.filter { $0 != userLinguaWindow }
        return windows?.first(where: \.isKeyWindow) ?? windows?.last
    }

    func showUserLinguaWindow() {
        userLinguaWindow.windowScene = UIApplication.shared.windowScene
        userLinguaWindow.makeKeyAndVisible()
    }

    func hideUserLinguaWindow() {
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

enum WindowManagerDependency: DependencyKey {
    static let liveValue: any WindowManagerProtocol = { fatalError("WindowManager not supplied") }()
    static let previewValue: any WindowManagerProtocol = WindowManagerProtocolSpy()
    static let testValue: any WindowManagerProtocol = WindowManagerProtocolSpy()
}
