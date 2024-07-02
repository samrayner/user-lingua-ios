// Theme+Components.swift

extension ModuleColors {
    public var horizontalRule: ModuleColor { \.surface }

    public var primaryButtonText: ModuleColor { \.onPrimary }
    public var primaryButtonTextDisabled: ModuleColor { \.foreground }
    public var primaryButtonBackground: ModuleColor { \.primary }
    public var primaryButtonBackgroundDisabled: ModuleColor { \.surface }
}

extension ModuleFonts {
    public var primaryButton: ModuleFont { \.button }
}
