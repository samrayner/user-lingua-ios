// Image+Templated.swift

import SwiftUI

extension Image {
    package func templated(color: KeyPath<ModuleColors, ModuleColor>) -> some View {
        renderingMode(.template)
            .foregroundColor(.theme(color))
    }
}
