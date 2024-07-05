// SwizzlerProtocol.swift

// sourcery: AutoMockable
public protocol SwizzlerProtocol {
    func swizzleForForeground()
    func unswizzleForForeground()
    func swizzleForBackground()
    func unswizzleForBackground()
}
