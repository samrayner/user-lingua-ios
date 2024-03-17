// NSObjectWrapper.swift

import Foundation

final class NSObjectWrapper<Wrapped>: NSObject {
    let wrapped: Wrapped

    init(_ wrapped: Wrapped) {
        self.wrapped = wrapped
    }
}
