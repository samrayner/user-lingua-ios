// CodableCVarArg.swift

import Foundation

// Based on https://github.com/Flight-School/AnyCodable

@frozen
public struct CodableCVarArg: Codable {
    public let value: CVarArg

    public init(_ value: CVarArg) {
        self.value = value
    }
}

extension CodableCVarArg: _EncodableCVarArg, _DecodableCVarArg {}

extension CodableCVarArg: Equatable {
    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case let (lhs as Bool, rhs as Bool):
            lhs == rhs
        case let (lhs as Int, rhs as Int):
            lhs == rhs
        case let (lhs as Int8, rhs as Int8):
            lhs == rhs
        case let (lhs as Int16, rhs as Int16):
            lhs == rhs
        case let (lhs as Int32, rhs as Int32):
            lhs == rhs
        case let (lhs as Int64, rhs as Int64):
            lhs == rhs
        case let (lhs as UInt, rhs as UInt):
            lhs == rhs
        case let (lhs as UInt8, rhs as UInt8):
            lhs == rhs
        case let (lhs as UInt16, rhs as UInt16):
            lhs == rhs
        case let (lhs as UInt32, rhs as UInt32):
            lhs == rhs
        case let (lhs as UInt64, rhs as UInt64):
            lhs == rhs
        case let (lhs as Float, rhs as Float):
            lhs == rhs
        case let (lhs as Double, rhs as Double):
            lhs == rhs
        case let (lhs as String, rhs as String):
            lhs == rhs
        case let (lhs as [String: CodableCVarArg], rhs as [String: CodableCVarArg]):
            lhs == rhs
        case let (lhs as [CodableCVarArg], rhs as [CodableCVarArg]):
            lhs == rhs
        case let (lhs as [String: CVarArg], rhs as [String: CVarArg]):
            NSDictionary(dictionary: lhs) == NSDictionary(dictionary: rhs)
        case let (lhs as [CVarArg], rhs as [CVarArg]):
            NSArray(array: lhs) == NSArray(array: rhs)
        default:
            false
        }
    }
}

extension CodableCVarArg: CustomStringConvertible {
    public var description: String {
        switch value {
        case let value as CustomStringConvertible:
            value.description
        default:
            String(describing: value)
        }
    }
}

extension CodableCVarArg: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch value {
        case let value as CustomDebugStringConvertible:
            "CodableCVarArg(\(value.debugDescription))"
        default:
            "CodableCVarArg(\(description))"
        }
    }
}

extension CodableCVarArg: ExpressibleByNilLiteral {}
extension CodableCVarArg: ExpressibleByBooleanLiteral {}
extension CodableCVarArg: ExpressibleByIntegerLiteral {}
extension CodableCVarArg: ExpressibleByFloatLiteral {}
extension CodableCVarArg: ExpressibleByStringLiteral {}
extension CodableCVarArg: ExpressibleByStringInterpolation {}
extension CodableCVarArg: ExpressibleByArrayLiteral {}
extension CodableCVarArg: ExpressibleByDictionaryLiteral {}

extension CodableCVarArg: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch value {
        case let value as Bool:
            hasher.combine(value)
        case let value as Int:
            hasher.combine(value)
        case let value as Int8:
            hasher.combine(value)
        case let value as Int16:
            hasher.combine(value)
        case let value as Int32:
            hasher.combine(value)
        case let value as Int64:
            hasher.combine(value)
        case let value as UInt:
            hasher.combine(value)
        case let value as UInt8:
            hasher.combine(value)
        case let value as UInt16:
            hasher.combine(value)
        case let value as UInt32:
            hasher.combine(value)
        case let value as UInt64:
            hasher.combine(value)
        case let value as Float:
            hasher.combine(value)
        case let value as Double:
            hasher.combine(value)
        case let value as String:
            hasher.combine(value)
        case let value as [String: CodableCVarArg]:
            hasher.combine(value)
        case let value as [CodableCVarArg]:
            hasher.combine(value)
        default:
            break
        }
    }
}
