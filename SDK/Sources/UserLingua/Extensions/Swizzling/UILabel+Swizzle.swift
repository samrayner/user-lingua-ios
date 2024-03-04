// UILabel+Swizzle.swift

import UIKit

extension UILabel {
    private static let notificationObservationAssociation = ObjectAssociation<NSObjectProtocol>()
    private static let unprocessedTextAssociation = ObjectAssociation<NSString>()

    var notificationObservation: NSObjectProtocol? {
        get { Self.notificationObservationAssociation[self] }
        set { Self.notificationObservationAssociation[self] = newValue }
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
        guard notificationObservation == nil else { return }

        notificationObservation = NotificationCenter.default.addObserver(
            forName: .userLinguaObjectDidChange,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            self?.userLinguaDidChange(notification)
        }
    }

    @objc
    func userLinguaDidChange(_: Notification) {
        // call the swizzled text setter to re-evaluate the current text based on UserLingua's state
        if unprocessedText != nil {
            text = unprocessedText
        }
    }
}
