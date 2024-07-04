// Reflection.swift

public enum Reflection {
    public static func value(
        _ label: String,
        on object: Any
    ) -> Any? {
        let reflection = Mirror(reflecting: object)
        return reflection.children
            .first(where: { $0.label == label })?
            .value
    }
}
