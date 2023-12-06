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

extension UIView {
    private static let observationAssociation = ObjectAssociation<NSObjectProtocol>()
    
    var observation: NSObjectProtocol? {
        get { return Self.observationAssociation[self] }
        set { Self.observationAssociation[self] = newValue }
    }
    
    static func swizzle() {
        swizzle(
            original: #selector(layoutSubviews),
            with: #selector(swizzledLayoutSubviews)
        )
    }
    
    @objc func swizzledLayoutSubviews() {
        swizzledLayoutSubviews()
        guard observation == nil else { return }
        
        switch self {
        case is UILabel:
            observation = NotificationCenter.default.addObserver(forName: .userLinguaObjectWillChange, object: nil, queue: nil) { [weak self] notification in
                self?.didFire(notification)
            }
        default:
            return
        }
    }
    
    @objc func didFire(_ notification: Notification) {
        switch self {
        case let label as UILabel:
            if let oldText = label.text {
                label.text = UserLingua.shared.processString(oldText, localize: false)
            }
        case let textField as UITextField:
            if let oldPlaceholder = textField.placeholder {
                textField.placeholder = UserLingua.shared.processString(oldPlaceholder, localize: false)
            }
            if let oldText = textField.text {
                textField.text = UserLingua.shared.processString(oldText, localize: false)
            }
        case let textView as UITextView:
            if let oldText = textView.text {
                textView.text = UserLingua.shared.processString(oldText, localize: false)
            }
        default:
            return
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
    static let userLinguaObjectWillChange = Notification.Name("userLinguaObjectWillChange")
    static let deviceDidShake = NSNotification.Name("deviceDidShake")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }
        NotificationCenter.default.post(name: .deviceDidShake, object: nil)
    }
}
