// UserLinguaMacros.swift

@attached(member, names: named(userLinguaObservedObject))
public macro UserLingua() = #externalMacro(module: "Macros", type: "UserLinguaMacro")
