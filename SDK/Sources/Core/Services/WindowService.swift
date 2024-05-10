// WindowService.swift

import Dependencies
import SwiftUI
import UIKit

// sourcery: AutoMockable
package protocol WindowServiceProtocol {
    var userLinguaWindow: UIWindow { get }
    var appUIStyle: UIUserInterfaceStyle { get }
    var appYOffset: CGFloat { get }
    func setRootView(_: some View)
    func screenshotAppWindow() -> UIImage?
    func showWindow()
    func hideWindow()
    func toggleDarkMode()
    func positionApp(focusing: CGPoint, within: CGRect, animationDuration: TimeInterval)
    func positionApp(yOffset: CGFloat, animationDuration: TimeInterval)
    func resetAppPosition()
    func resetAppWindow()
}

package final class WindowService: WindowServiceProtocol {
    package init() {}

    var appWindow: UIWindow?
    var originalAppWindowUIStyleOverride: UIUserInterfaceStyle = .unspecified

    package var appUIStyle: UIUserInterfaceStyle {
        guard let appWindow, appWindow.overrideUserInterfaceStyle != .unspecified else {
            return UIScreen.main.traitCollection.userInterfaceStyle
        }

        return appWindow.overrideUserInterfaceStyle
    }

    package var appYOffset: CGFloat {
        appWindow?.layer.translationIn2D.y ?? 0
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

    package func toggleDarkMode() {
        appWindow?.toggleDarkMode()
    }

    package func positionApp(focusing focalPoint: CGPoint, within viewportFrame: CGRect, animationDuration: TimeInterval = 0) {
        guard let appWindow else { return }

        let maxTranslateUp = viewportFrame.maxY - appWindow.bounds.maxY
        let maxTranslateDown = viewportFrame.minY
        let yOffset = (viewportFrame.midY - focalPoint.y).clamped(to: maxTranslateUp ... maxTranslateDown)

        positionApp(
            yOffset: yOffset,
            animationDuration: animationDuration
        )
    }

    package func positionApp(yOffset: CGFloat, animationDuration: TimeInterval = 0) {
        guard let appWindow else { return }

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

    package func resetAppPosition() {
        positionApp(yOffset: 0)
        // hack sometimes required to force the window to redraw
        appWindow?.isHidden.toggle()
        appWindow?.isHidden.toggle()
    }

    package func resetAppWindow() {
        resetAppPosition()
        appWindow?.overrideUserInterfaceStyle = originalAppWindowUIStyleOverride
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

package enum WindowServiceDependency: DependencyKey {
    package static let liveValue: any WindowServiceProtocol = WindowService()
    package static let previewValue: any WindowServiceProtocol = WindowServiceProtocolMock()
    package static let testValue: any WindowServiceProtocol = WindowServiceProtocolMock()
}
