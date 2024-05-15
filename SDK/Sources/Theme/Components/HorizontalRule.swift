// HorizontalRule.swift

import SwiftUI

public struct HorizontalRule: View {
    public let color: Color

    public init(color: Color = .theme(\.horizontalRule)) {
        self.color = color
    }

    public var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }
}
