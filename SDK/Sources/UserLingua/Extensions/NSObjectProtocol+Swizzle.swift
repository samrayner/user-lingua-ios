// NSObjectProtocol+Swizzle.swift

import UIKit

extension NSObjectProtocol {
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

final class ObjectAssociation<T: NSObjectProtocol> {
    private let policy: objc_AssociationPolicy

    init(policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) {
        self.policy = policy
    }

    subscript(index: NSObjectProtocol) -> T? {
        get {
            objc_getAssociatedObject(index, Unmanaged.passUnretained(self).toOpaque())
                .flatMap { $0 as? T }
        }
        set { objc_setAssociatedObject(index, Unmanaged.passUnretained(self).toOpaque(), newValue, policy) }
    }
}
