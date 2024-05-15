// GeneratePlaceholder.swift

extension _DefaultInitializable { fileprivate static var placeholder: Self { Self() } }
extension AdditiveArithmetic { fileprivate static var placeholder: Self { .zero } }
extension ExpressibleByArrayLiteral { fileprivate static var placeholder: Self { [] } }
extension ExpressibleByBooleanLiteral { fileprivate static var placeholder: Self { false } }
extension ExpressibleByDictionaryLiteral { fileprivate static var placeholder: Self { [:] } }
extension ExpressibleByFloatLiteral { fileprivate static var placeholder: Self { 0.0 } }
extension ExpressibleByIntegerLiteral { fileprivate static var placeholder: Self { 0 } }
extension ExpressibleByUnicodeScalarLiteral { fileprivate static var placeholder: Self { " " } }
extension RangeReplaceableCollection { fileprivate static var placeholder: Self { Self() } }

private protocol _OptionalProtocol { static var none: Self { get } }
extension Optional: _OptionalProtocol {}
private func _optionalPlaceholder<Result>() throws -> Result {
    if let result = (Result.self as? _OptionalProtocol.Type) {
        return result.none as! Result
    }
    throw PlaceholderGenerationFailure()
}

private func _placeholder<Result>() -> Result? {
    switch Result.self {
    case let type as _DefaultInitializable.Type: type.placeholder as? Result
    case is Void.Type: () as? Result
    case let type as any RangeReplaceableCollection.Type: type.placeholder as? Result
    case let type as any AdditiveArithmetic.Type: type.placeholder as? Result
    case let type as any ExpressibleByArrayLiteral.Type: type.placeholder as? Result
    case let type as any ExpressibleByBooleanLiteral.Type: type.placeholder as? Result
    case let type as any ExpressibleByDictionaryLiteral.Type: type.placeholder as? Result
    case let type as any ExpressibleByFloatLiteral.Type: type.placeholder as? Result
    case let type as any ExpressibleByIntegerLiteral.Type: type.placeholder as? Result
    case let type as any ExpressibleByUnicodeScalarLiteral.Type: type.placeholder as? Result
    default: nil
    }
}

private func _rawRepresentable<Result>() -> Result? {
    func posiblePlaceholder<T: RawRepresentable>(for _: T.Type) -> T? {
        (_placeholder() as T.RawValue?).flatMap(T.init(rawValue:))
    }

    return (Result.self as? any RawRepresentable.Type).flatMap {
        posiblePlaceholder(for: $0) as? Result
    }
}

private func _caseIterable<Result>() -> Result? {
    func firstCase<T: CaseIterable>(for _: T.Type) -> Result? {
        T.allCases.first as? Result
    }

    return (Result.self as? any CaseIterable.Type).flatMap {
        firstCase(for: $0)
    }
}

struct PlaceholderGenerationFailure: Error {}
func _generatePlaceholder<Result>() throws -> Result {
    if let result = _placeholder() as Result? {
        return result
    }

    if let result = _rawRepresentable() as Result? {
        return result
    }

    if let result = _caseIterable() as Result? {
        return result
    }

    return try _optionalPlaceholder()
}
