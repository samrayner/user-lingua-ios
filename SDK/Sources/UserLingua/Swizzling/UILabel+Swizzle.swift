// UILabel+Swizzle.swift

import Combine
import Core
import UIKit

extension UILabel {
    private static let refreshCancellableAssociation = ObjectAssociation<NSObjectWrapper<AnyCancellable>>()
    private static let unprocessedTextAssociation = ObjectAssociation<NSString>()

    var refreshCancellable: AnyCancellable? {
        get { Self.refreshCancellableAssociation[self]?.wrapped }
        set { Self.refreshCancellableAssociation[self] = newValue.map(NSObjectWrapper.init) }
    }

    var unprocessedText: String? {
        get { Self.unprocessedTextAssociation[self] as String? }
        set { Self.unprocessedTextAssociation[self] = newValue as NSString? }
    }

    static func swizzle() {
        swizzle(
            original: #selector(didMoveToSuperview),
            with: #selector(unswizzledDidMoveToSuperview)
        )

        swizzle(
            original: #selector(setter: text),
            with: #selector(unswizzledSetText)
        )
    }

    static func unswizzle() {
        swizzle(
            original: #selector(unswizzledDidMoveToSuperview),
            with: #selector(didMoveToSuperview)
        )

        swizzle(
            original: #selector(unswizzledSetText),
            with: #selector(setter: text)
        )
    }

    // After swizzling, unswizzled... will refer to the original implementation
    // and the original method name will call the below implementation.
    @objc
    func unswizzledSetText(_ text: String?) {
        guard !UserLingua.isDisabled(for: self) else {
            unswizzledSetText(text)
            return
        }

        unprocessedText = text
        let processedString = text.map { UserLingua.shared.processString($0) }
        unswizzledSetText(processedString)
    }

    @objc
    func unswizzledDidMoveToSuperview() {
        unswizzledDidMoveToSuperview()
        guard refreshCancellable == nil else { return }

        refreshCancellable = UserLingua.shared.viewModel.refreshPublisher
            .sink { [weak self] in
                self?.refresh()
            }
    }

    func refresh() {
        // call the swizzled text setter to re-evaluate the current text based on UserLingua's state
        if unprocessedText != nil {
            text = unprocessedText
        }
    }
}
