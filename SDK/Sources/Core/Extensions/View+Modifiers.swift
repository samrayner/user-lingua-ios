// View+Modifiers.swift

import Foundation
import SwiftUI

extension View {
    package func border(
        _ content: some ShapeStyle,
        cornerRadius: CGFloat,
        width: CGFloat = 1
    ) -> some View {
        self
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .inset(by: width)
                    .stroke(content, lineWidth: width)
            )
    }
}
