// Perceptible.swift

/// A type that emits notifications to observers when underlying data changes.
///
/// Conforming to this protocol signals to other APIs that the type supports
/// observation. However, applying the `Perceptible` protocol by itself to a
/// type doesn't add observation functionality to the type. Instead, always use
/// the ``Perception/Perceptible()`` macro when adding observation
/// support to a type.
@available(iOS, deprecated: 17, renamed: "Observable")
@available(macOS, deprecated: 14, renamed: "Observable")
@available(tvOS, deprecated: 17, renamed: "Observable")
@available(watchOS, deprecated: 10, renamed: "Observable")
public protocol Perceptible {}
