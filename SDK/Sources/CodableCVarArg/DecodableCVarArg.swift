// DecodableCVarArg.swift

import Foundation

// Based on https://github.com/Flight-School/AnyCodable

@frozen
public struct DecodableCVarArg: Decodable {
    public let value: CVarArg

    public init(_ value: CVarArg) {
        self.value = value
    }
}

@usableFromInline
protocol _DecodableCVarArg {
    var value: CVarArg { get }
    init(_ value: CVarArg)
}

extension DecodableCVarArg: _DecodableCVarArg {}

extension _DecodableCVarArg {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let bool = try? container.decode(Bool.self) {
            self.init(bool)
        } else if let int = try? container.decode(Int.self) {
            self.init(int)
        } else if let uint = try? container.decode(UInt.self) {
            self.init(uint)
        } else if let double = try? container.decode(Double.self) {
            self.init(double)
        } else if let string = try? container.decode(String.self) {
            self.init(string)
        } else if let array = try? container.decode([DecodableCVarArg].self) {
            self.init(array.map { $0.value })
        } else if let dictionary = try? container.decode([String: DecodableCVarArg].self) {
            self.init(dictionary.mapValues { $0.value })
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "DecodableCVarArg value cannot be decoded")
        }
    }
}

extension DecodableCVarArg: Equatable {
    public static func == (lhs: AnyDecodable, rhs: AnyDecodable) -> Bool {
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
        case let (lhs as [String: DecodableCVarArg], rhs as [String: DecodableCVarArg]):
            lhs == rhs
        case let (lhs as [DecodableCVarArg], rhs as [DecodableCVarArg]):
            lhs == rhs
        default:
            false
        }
    }
}

extension DecodableCVarArg: CustomStringConvertible {
    public var description: String {
        switch value {
        case let value as CustomStringConvertible:
            value.description
        default:
            String(describing: value)
        }
    }
}

extension DecodableCVarArg: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch value {
        case let value as CustomDebugStringConvertible:
            "DecodableCVarArg(\(value.debugDescription))"
        default:
            "DecodableCVarArg(\(description))"
        }
    }
}

extension DecodableCVarArg: Hashable {
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
        case let value as [String: DecodableCVarArg]:
            hasher.combine(value)
        case let value as [DecodableCVarArg]:
            hasher.combine(value)
        default:
            break
        }
    }
}
