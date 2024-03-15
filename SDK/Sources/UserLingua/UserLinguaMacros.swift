// UserLinguaMacros.swift

@attached(member, names: named(_userLinguaViewModel))
public macro UserLingua() = #externalMacro(module: "Macros", type: "UserLinguaMacro")
