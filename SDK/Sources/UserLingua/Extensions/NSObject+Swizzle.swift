import UIKit

private extension NSObject {
    static func swizzle(original originalSelector: Selector, with newSelector: Selector) {
        guard let originalMethod = class_getInstanceMethod(self, originalSelector) else { return }
        guard let newMethod = class_getInstanceMethod(self, newSelector) else { return }
        
        if class_addMethod(self, originalSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)) {
            class_replaceMethod(self, newSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, newMethod)
        }
    }
}

extension Bundle {
    static func swizzle() {
        swizzle(
            original: #selector(localizedString(forKey:value:table:)),
            with: #selector(swizzledLocalizedString(forKey:value:table:))
        )
    }
    
    @objc func swizzledLocalizedString(forKey key: String, value: String?, table: String?) -> String {
        let value = swizzledLocalizedString(forKey: key, value: value, table: table)
        UserLingua.shared.db.record(
            localizedString: LocalizedString(
                value: value,
                localization: Localization(key: key, bundle: self, tableName: table, comment: nil)
            )
        )
        return value
    }
}

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

public final class ObjectAssociation<T: NSObjectProtocol> {
    private let policy: objc_AssociationPolicy

    public init(policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) {
        self.policy = policy
    }

    public subscript(index: NSObjectProtocol) -> T? {
        get { return objc_getAssociatedObject(index, Unmanaged.passUnretained(self).toOpaque()) as! T? }
        set { objc_setAssociatedObject(index, Unmanaged.passUnretained(self).toOpaque(), newValue, policy) }
    }
}

extension Notification.Name {
    static let userLinguaObjectDidChange = Notification.Name("userLinguaObjectDidChange")
    static let deviceDidShake = NSNotification.Name("deviceDidShake")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }
        NotificationCenter.default.post(name: .deviceDidShake, object: nil)
    }
}
