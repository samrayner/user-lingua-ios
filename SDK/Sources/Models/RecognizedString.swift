// RecognizedString.swift

import Foundation

public struct RecognizedString: Equatable {
    public let id = UUID()
    public var recordedString: RecordedString
    public var lines: [RecognizedLine]

    public init(
        recordedString: RecordedString,
        lines: [RecognizedLine]
    ) {
        self.recordedString = recordedString
        self.lines = lines
    }

    public var localization: Localization? {
        recordedString.localization
    }

    public var hasAlternativeLocalizations: Bool {
        guard let localizationCount = localization?.bundle?.localizations.count else { return false }
        return localizationCount > 1
    }

    public var isLocalized: Bool {
        localization != nil
    }

    public var value: String {
        recordedString.value
    }

    public var boundingBox: CGRect {
        guard let firstLineFrame = lines.first?.boundingBox else { return .zero }

        return lines.dropFirst().reduce(into: firstLineFrame) { boundingBox, line in
            boundingBox = boundingBox.union(line.boundingBox)
        }
    }

    public var boundingBoxCenter: CGPoint {
        let boundingBox = boundingBox

        return CGPoint(
            x: boundingBox.midX,
            y: boundingBox.midY
        )
    }

    public func localizedValue(locale: Locale) -> String {
        recordedString.localizedValue(locale: locale)
    }

    public func localizedValue(
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
