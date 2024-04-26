// Comparable+Clamped.swift

import Foundation

extension Comparable {
    package func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(limits.lowerBound, self), limits.upperBound)
    }
}

extension Strideable where Stride: SignedInteger {
    package func clamped(to limits: Range<Self>) -> Self {
        clamped(to: ClosedRange(limits))
    }
}
