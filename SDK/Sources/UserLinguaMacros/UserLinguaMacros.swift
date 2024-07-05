// UserLinguaMacros.swift

@attached(member, names: named(_userLinguaViewModel))
public macro CopyEditable() = #externalMacro(module: "UserLinguaExternalMacros", type: "CopyEditableMacro")
