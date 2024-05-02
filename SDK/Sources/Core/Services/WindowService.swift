// WindowService.swift

import Dependencies
import SwiftUI
import UIKit

package protocol WindowServiceProtocol {
    var userLinguaWindow: UIWindow { get }
    var appUIStyle: UIUserInterfaceStyle { get }
    var appYOffset: CGFloat { get }
    func setRootView(_: some View)
    func screenshotAppWindow() -> UIImage?
    func showWindow()
    func hideWindow()
    func toggleDarkMode()
    func positionApp(focusing: CGPoint, in: CGRect, animationDuration: TimeInterval)
    func positionApp(yOffset: CGFloat, animationDuration: TimeInterval)
    func resetAppWindow()
}

package final class WindowService: WindowServiceProtocol {
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

    package func positionApp(focusing focalPoint: CGPoint, in viewportFrame: CGRect, animationDuration: TimeInterval = 0) {
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

    package func resetAppWindow() {
        positionApp(yOffset: 0)
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
    package static let previewValue: any WindowServiceProtocol = WindowServiceProtocolSpy()
    package static let testValue: any WindowServiceProtocol = WindowServiceProtocolSpy()
}
