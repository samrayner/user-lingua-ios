// UIView+Swizzle.swift

import Combine
import Core
import UIKit

extension UIView {
    private static let contentSizeCategoryCancellableAssociation = ObjectAssociation<NSObjectWrapper<AnyCancellable>>()

    var contentSizeCategoryCancellable: AnyCancellable? {
        get { Self.contentSizeCategoryCancellableAssociation[self]?.wrapped }
        set { Self.contentSizeCategoryCancellableAssociation[self] = newValue.map(NSObjectWrapper.init) }
    }

    static func swizzleAll() {
        swizzle(
            original: #selector(layoutSubviews),
            with: #selector(unswizzledLayoutSubviews)
        )
    }

    static func unswizzleAll() {
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
                    if self?.window != UserLingua.shared.window {
                        self?.traitCollectionDidChange(nil)
                    }
                }
        }
    }
}
