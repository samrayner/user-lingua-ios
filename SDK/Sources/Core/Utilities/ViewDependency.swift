// ViewDependency.swift

import Foundation
import SwiftUI

@dynamicMemberLookup
public final class ViewDependency<Dependency>: ObservableObject {
    public let dependency: Dependency

    public init(_ dependency: Dependency) {
        self.dependency = dependency
    }

    public subscript<Value>(dynamicMember keyPath: KeyPath<Dependency, Value>) -> Value {
        dependency[keyPath: keyPath]
    }
}
