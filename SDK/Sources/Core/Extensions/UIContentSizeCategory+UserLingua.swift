// UIContentSizeCategory+UserLingua.swift

import UIKit

extension UIContentSizeCategory {
    package static var isUserLinguaNotificationUserInfoKey: String { #function }

    private var knownCases: [UIContentSizeCategory] {
        [
            .extraSmall,
            .small,
            .medium,
            .large,
            .extraLarge,
            .extraExtraLarge,
            .extraExtraExtraLarge,
            .accessibilityMedium,
            .accessibilityLarge,
            .accessibilityExtraLarge,
            .accessibilityExtraExtraLarge,
            .accessibilityExtraExtraExtraLarge
        ]
    }

    package var fixedFontSize: CGFloat {
        switch self {
        case .extraSmall: 10
        case .small: 12
        case .medium: 14
        case .large: 16
        case .extraLarge: 18
        case .extraExtraLarge: 20
        case .extraExtraExtraLarge: 22
        case .accessibilityMedium: 24
        case .accessibilityLarge: 26
        case .accessibilityExtraLarge: 28
        case .accessibilityExtraExtraLarge: 30
        case .accessibilityExtraExtraExtraLarge: 32
        case .unspecified: UIContentSizeCategory.medium.fixedFontSize
        default: UIContentSizeCategory.medium.fixedFontSize
        }
    }

    package func incremented() -> Self {
        if let index = knownCases.firstIndex(of: self), index < knownCases.endIndex - 1 {
            knownCases[index + 1]
        } else {
            self
        }
    }

    package func decremented() -> Self {
        if let index = knownCases.firstIndex(of: self), index > knownCases.startIndex {
            knownCases[index - 1]
        } else {
            self
        }
    }
}
