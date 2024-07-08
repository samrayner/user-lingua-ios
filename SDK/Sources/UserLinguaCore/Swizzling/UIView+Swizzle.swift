// UIView+Swizzle.swift

import Combine
import UIKit

extension UIView {
    private static let contentSizeCategoryCancellableAssociation = ObjectAssociation<NSObjectWrapper<AnyCancellable>>()

    var contentSizeCategoryCancellable: AnyCancellable? {
        get { Self.contentSizeCategoryCancellableAssociation[self]?.wrapped }
        set { Self.contentSizeCategoryCancellableAssociation[self] = newValue.map(NSObjectWrapper.init) }
    }

    static func swizzleUIView() {
        swizzle(
            original: #selector(layoutSubviews),
            with: #selector(unswizzledLayoutSubviews)
        )
    }

    static func unswizzleUIView() {
        swizzle(
            original: #selector(unswizzledLayoutSubviews),
            with: #selector(layoutSubviews)
        )
    }

    @objc
    func unswizzledLayoutSubviews() {
        unswizzledLayoutSubviews()

        if contentSizeCategoryCancellable == nil {
            contentSizeCategoryCancellable = NotificationCenter.default
                .publisher(for: UIContentSizeCategory.didChangeNotification)
                .filter { $0.userInfo?[UIContentSizeCategory.isUserLinguaNotificationUserInfoKey] as? Bool == true }
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    guard let self else { return }
                    if ![self, window].contains(UserLinguaClient.shared.window) {
                        traitCollectionDidChange(nil)

                        // hack to force UIButtons to resize text
                        if let window = self as? UIWindow {
                            window.toggleDarkMode()
                            window.toggleDarkMode()
                        }
                    }
                }
        }
    }
}
