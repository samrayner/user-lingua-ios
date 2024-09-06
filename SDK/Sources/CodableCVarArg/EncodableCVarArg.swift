// EncodableCVarArg.swift

import Foundation

// Based on https://github.com/Flight-School/AnyCodable

@frozen
public struct EncodableCVarArg: Encodable {
    public let value: CVarArg

    public init(_ value: CVarArg) {
        self.value = value
    }
}

@usableFromInline
protocol _EncodableCVarArg {
    var value: CVarArg { get }
    init(_ value: CVarArg)
}

extension EncodableCVarArg: _EncodableCVarArg {}

// MARK: - Encodable

extension _EncodableCVarArg {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let int8 as Int8:
            try container.encode(int8)
        case let int16 as Int16:
            try container.encode(int16)
        case let int32 as Int32:
            try container.encode(int32)
        case let int64 as Int64:
            try container.encode(int64)
        case let uint as UInt:
            try container.encode(uint)
        case let uint8 as UInt8:
            try container.encode(uint8)
        case let uint16 as UInt16:
            try container.encode(uint16)
        case let uint32 as UInt32:
            try container.encode(uint32)
        case let uint64 as UInt64:
            try container.encode(uint64)
        case let float as Float:
            try container.encode(float)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any?]:
            try container.encode(array.map { EncodableCVarArg($0) })
        case let dictionary as [String: Any?]:
            try container.encode(dictionary.mapValues { EncodableCVarArg($0) })
        case let encodable as Encodable:
            try encodable.encode(to: encoder)
        default:
            let context = EncodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "EncodableCVarArg value cannot be encoded"
            )
            throw EncodingError.invalidValue(value, context)
        }
    }
}

extension EncodableCVarArg: Equatable {
    public static func == (lhs: EncodableCVarArg, rhs: EncodableCVarArg) -> Bool {
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
        case let (lhs as [String: EncodableCVarArg], rhs as [String: EncodableCVarArg]):
            lhs == rhs
        case let (lhs as [EncodableCVarArg], rhs as [EncodableCVarArg]):
            lhs == rhs
        default:
            false
        }
    }
}

extension EncodableCVarArg: CustomStringConvertible {
    public var description: String {
        switch value {
        case let value as CustomStringConvertible:
            value.description
        default:
            String(describing: value)
        }
    }
}

extension EncodableCVarArg: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch value {
        case let value as CustomDebugStringConvertible:
            "EncodableCVarArg(\(value.debugDescription))"
        default:
            "EncodableCVarArg(\(description))"
        }
    }
}

extension EncodableCVarArg: ExpressibleByNilLiteral {}
extension EncodableCVarArg: ExpressibleByBooleanLiteral {}
extension EncodableCVarArg: ExpressibleByIntegerLiteral {}
extension EncodableCVarArg: ExpressibleByFloatLiteral {}
extension EncodableCVarArg: ExpressibleByStringLiteral {}
extension EncodableCVarArg: ExpressibleByStringInterpolation {}
extension EncodableCVarArg: ExpressibleByArrayLiteral {}
extension EncodableCVarArg: ExpressibleByDictionaryLiteral {}

extension _EncodableCVarArg {
    public init(booleanLiteral value: Bool) {
        self.init(value)
    }

    public init(integerLiteral value: Int) {
        self.init(value)
    }

    public init(floatLiteral value: Double) {
        self.init(value)
    }

    public init(extendedGraphemeClusterLiteral value: String) {
        self.init(value)
    }

    public init(stringLiteral value: String) {
        self.init(value)
    }

    public init(arrayLiteral elements: Any...) {
        self.init(elements)
    }

    public init(dictionaryLiteral elements: (AnyHashable, Any)...) {
        self.init([AnyHashable: Any](elements, uniquingKeysWith: { first, _ in first }))
    }
}

extension EncodableCVarArg: Hashable {
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
        case let value as [String: EncodableCVarArg]:
            hasher.combine(value)
        case let value as [EncodableCVarArg]:
            hasher.combine(value)
        default:
            break
        }
    }
}
