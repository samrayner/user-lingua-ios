// Theme+Components.swift

extension ModuleColors {
    var horizontalRule: ModuleColor { \.surface }

    var primaryButtonText: ModuleColor { \.onPrimary }
    var primaryButtonTextDisabled: ModuleColor { \.foreground }
    var primaryButtonBackground: ModuleColor { \.primary }
    var primaryButtonBackgroundDisabled: ModuleColor { \.surface }
}

extension ModuleFonts {
    var primaryButton: ModuleFont { \.button }
}
