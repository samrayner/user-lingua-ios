// ThreadLocal.swift

import Foundation

enum _ThreadLocal {
    static var value: UnsafeMutableRawPointer? {
        get {
            Thread.current.threadDictionary[Key()] as! UnsafeMutableRawPointer?
        }
        set {
            Thread.current.threadDictionary[Key()] = newValue
        }
    }
}

private struct Key: Hashable {}
