import Foundation

// Used for String formatting method overloads
// as it is considered more specific than CVarArg
// so the compiler gives it precedence.
public protocol UserLinguaCVarArg: CVarArg {}

// https://developer.apple.com/documentation/swift/cvararg#conforming-types

extension Array: UserLinguaCVarArg {}
extension AutoreleasingUnsafeMutablePointer: UserLinguaCVarArg {}
extension Bool: UserLinguaCVarArg {}
extension Dictionary: UserLinguaCVarArg where Key: Hashable {}
extension Double: UserLinguaCVarArg {}
extension Float: UserLinguaCVarArg {}
extension Float80: UserLinguaCVarArg {}
extension Int: UserLinguaCVarArg {}
extension Int16: UserLinguaCVarArg {}
extension Int32: UserLinguaCVarArg {}
extension Int64: UserLinguaCVarArg {}
extension Int8: UserLinguaCVarArg {}
extension OpaquePointer: UserLinguaCVarArg {}
extension Set: UserLinguaCVarArg where Element: Hashable {}
extension String: UserLinguaCVarArg {}
extension UInt: UserLinguaCVarArg {}
extension UInt16: UserLinguaCVarArg {}
extension UInt32: UserLinguaCVarArg {}
extension UInt64: UserLinguaCVarArg {}
extension UInt8: UserLinguaCVarArg {}
extension UnsafeMutablePointer: UserLinguaCVarArg {}
extension UnsafePointer: UserLinguaCVarArg {}
