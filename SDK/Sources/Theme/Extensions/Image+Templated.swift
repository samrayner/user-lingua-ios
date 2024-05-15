// Image+Templated.swift

import SwiftUI

extension Image {
    public func templated(color: KeyPath<ModuleColors, ModuleColor>) -> some View {
        renderingMode(.template)
            .foregroundColor(.theme(color))
    }
}
