// UIContentSizeCategory+UserLingua.swift

import UIKit

extension UIContentSizeCategory {
    public static var isUserLinguaNotificationUserInfoKey: String { #function }

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

    public var fontScaleFactor: CGFloat {
        switch self {
        case .extraSmall: 0.6
        case .small: 0.8
        case .medium: 1
        case .large: 1.2
        case .extraLarge: 1.4
        case .extraExtraLarge: 1.6
        case .extraExtraExtraLarge: 1.8
        case .accessibilityMedium: 2
        case .accessibilityLarge: 2.2
        case .accessibilityExtraLarge: 2.3
        case .accessibilityExtraExtraLarge: 2.4
        case .accessibilityExtraExtraExtraLarge: 2.6
        case .unspecified: UIContentSizeCategory.medium.fontScaleFactor
        default: UIContentSizeCategory.medium.fontScaleFactor
        }
    }

    public func incremented() -> Self {
        if let index = knownCases.firstIndex(of: self), index < knownCases.endIndex - 1 {
            knownCases[index + 1]
        } else {
            self
        }
    }

    public func decremented() -> Self {
        if let index = knownCases.firstIndex(of: self), index > knownCases.startIndex {
            knownCases[index - 1]
        } else {
            self
        }
    }
}
