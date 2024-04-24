// HorizontalRule.swift

import SwiftUI

package struct HorizontalRule: View {
    package let color: Color

    package init(color: Color = .theme(.horizontalRule)) {
        self.color = color
    }

    package var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }
}
