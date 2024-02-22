// UserLinguaMacros.swift

@attached(member, names: named(_userLinguaObservedObject))
public macro UserLingua() = #externalMacro(module: "Macros", type: "UserLinguaMacro")
