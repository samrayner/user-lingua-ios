// UserLinguaMacros.swift

@attached(member, names: named(_userLinguaViewModel))
public macro UserLingua() = #externalMacro(module: "UserLinguaMacros", type: "UserLinguaMacro")
