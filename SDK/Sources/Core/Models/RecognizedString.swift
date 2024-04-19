// RecognizedString.swift

import Foundation
import MemberwiseInit

@MemberwiseInit(.package)
package struct RecognizedString: Equatable {
    package let id = UUID()
    package var recordedString: RecordedString
    package var lines: [RecognizedLine]

    package var localization: Localization? {
        recordedString.localization
    }

    package var isLocalized: Bool {
        localization != nil
    }

    package var value: String {
        recordedString.value
    }

    package var boundingBox: CGRect {
        guard let firstLineFrame = lines.first?.boundingBox else { return .zero }

        return lines.dropFirst().reduce(into: firstLineFrame) { boundingBox, line in
            boundingBox = boundingBox.union(line.boundingBox)
        }
    }

    package var boundingBoxCenter: CGPoint {
        let boundingBox = boundingBox

        return CGPoint(
            x: boundingBox.midX,
            y: boundingBox.midY
        )
    }

    package func localizedValue(locale: Locale) -> String {
        recordedString.localizedValue(locale: locale)
    }

    package func localizedValue(
        locale: Locale,
        placeholderAttributes: [NSAttributedString.Key: Any],
        nonPlaceholderAttributes: [NSAttributedString.Key: Any] = [:],
        placeholderTransform: (String) -> String = { $0 }
    ) -> AttributedString {
        recordedString.localizedValue(
            locale: locale,
            placeholderAttributes: placeholderAttributes,
            nonPlaceholderAttributes: nonPlaceholderAttributes,
            placeholderTransform: placeholderTransform
        )
    }
}

extension RecognizedString: Identifiable {}
