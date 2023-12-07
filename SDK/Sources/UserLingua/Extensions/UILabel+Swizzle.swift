import UIKit

extension UILabel {
    private static let notificationObservationAssociation = ObjectAssociation<NSObjectProtocol>()
    private static let unprocessedTextAssociation = ObjectAssociation<NSString>()
    
    var notificationObservation: NSObjectProtocol? {
        get { return Self.notificationObservationAssociation[self] }
        set { Self.notificationObservationAssociation[self] = newValue }
    }
    
    var unprocessedText: String? {
        get { return Self.unprocessedTextAssociation[self] as String? }
        set { Self.unprocessedTextAssociation[self] = newValue as NSString? }
    }
    
    static func swizzle() {
        swizzle(
            original: #selector(didMoveToSuperview),
            with: #selector(swizzledDidMoveToSuperview)
        )
        
        swizzle(
            original: #selector(setter: text),
            with: #selector(swizzledSetText)
        )
    }
    
    @objc func swizzledSetText(_ text: String?) {
        unprocessedText = text
        let processedString = text.map { UserLingua.shared.processString($0, localize: false) }
        swizzledSetText(processedString) //confusingly, calls the unswizzled method
    }
    
    @objc func swizzledDidMoveToSuperview() {
        swizzledDidMoveToSuperview() //confusingly, calls the unswizzled method
        guard notificationObservation == nil else { return }
        
        notificationObservation = NotificationCenter.default.addObserver(
            forName: .userLinguaObjectDidChange,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            self?.didFire(notification)
        }
    }
    
    @objc func didFire(_ notification: Notification) {
        //call the swizzled text setter to re-evaluate the current text based on UserLingua's state
        if unprocessedText != nil {
            text = unprocessedText
        }
    }
}
