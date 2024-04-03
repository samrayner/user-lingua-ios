// Image+Templated.swift

import SwiftUI

extension Image {
    package func templated(color: ThemeColor) -> some View {
        renderingMode(.template)
            .foregroundColor(.theme(color))
    }
}
