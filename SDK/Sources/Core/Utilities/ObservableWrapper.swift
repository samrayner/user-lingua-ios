// ObservableWrapper.swift

import Foundation
import SwiftUI

@dynamicMemberLookup
public final class ObservableWrapper<WrappedValue>: ObservableObject {
    public let wrappedValue: WrappedValue

    public init(_ wrappedValue: WrappedValue) {
        self.wrappedValue = wrappedValue
    }

    public subscript<Value>(dynamicMember keyPath: KeyPath<WrappedValue, Value>) -> Value {
        wrappedValue[keyPath: keyPath]
    }
}
