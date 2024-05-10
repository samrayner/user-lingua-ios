// FormattedString.swift

import Foundation

package struct FormattedString {
    package var value: String
    package var format: StringFormat
    package var arguments: [FormattedStringArgument]

    package init(value: String, format: StringFormat, arguments: [FormattedStringArgument]) {
        self.value = value
        self.format = format
        self.arguments = arguments
    }

    package var localization: Localization? {
        format.localization
    }

    package var isLocalized: Bool {
        localization != nil
    }

    private func formattedArguments(locale: Locale) -> [CVarArg] {
        arguments.map { $0.value(locale: locale) }
    }

    package func localizedValue(locale: Locale) -> String {
        let localizedFormat = format.localizedValue(locale: locale)

        guard !arguments.isEmpty else { return localizedFormat }

        return String(
            format: localizedFormat,
            locale: locale,
            arguments: formattedArguments(locale: locale)
        )
    }

    package func localizedValue(
        locale: Locale,
        placeholderAttributes: [NSAttributedString.Key: Any],
        nonPlaceholderAttributes: [NSAttributedString.Key: Any] = [:],
        placeholderTransform transformPlaceholder: (String) -> String = { $0 }
    ) -> AttributedString {
        let localizedFormat = format.localizedValue(locale: locale)
        let placeholderAttributes = AttributeContainer(placeholderAttributes)
        let nonPlaceholderAttributes = AttributeContainer(nonPlaceholderAttributes)

        guard !arguments.isEmpty else {
            var attributedString = AttributedString(localizedFormat)
            attributedString.mergeAttributes(nonPlaceholderAttributes, mergePolicy: .keepNew)
            return attributedString
        }

        let formattedArguments = formattedArguments(locale: locale)

        let placeholderMatches = StringFormat.placeholderRegex
            .matches(
                in: localizedFormat,
                range: NSRange(localizedFormat.startIndex..., in: localizedFormat)
            )

        var attributedString = AttributedString()
        var formatIndex = localizedFormat.startIndex
        var placeholderIndex = 0

        for match in placeholderMatches {
            // safe to force unwrap as we got the range from the format to begin with
            let range = Range(match.range, in: localizedFormat)!

            // append the text between the previous placeholder (or string start) and this one
            var before = AttributedString(localizedFormat[formatIndex ..< range.lowerBound].replacing("%%", with: "%"))
            before.mergeAttributes(nonPlaceholderAttributes, mergePolicy: .keepNew)
            attributedString.append(before)

            let placeholder = String(localizedFormat[range])
            var arguments = formattedArguments

            if placeholder.firstMatch(of: #/%([1-9][0-9]*)\$/#) == nil {
                // placeholder with no position index so
                // only pass in the specific argument for the placeholder
                arguments = [formattedArguments[placeholderIndex]]
                placeholderIndex += 1
            }

            var attributedArgument = AttributedString(
                String(format: transformPlaceholder(placeholder), locale: locale, arguments: arguments)
            )
            attributedArgument.mergeAttributes(placeholderAttributes, mergePolicy: .keepNew)
            attributedString.append(attributedArgument)

            formatIndex = range.upperBound
        }

        var after = AttributedString(localizedFormat[formatIndex...].replacing("%%", with: "%"))
        after.setAttributes(nonPlaceholderAttributes)
        attributedString.append(after)

        return attributedString
    }
}

extension FormattedString {
    package init(_ format: StringFormat) {
        self.value = format.value
        self.format = format
        self.arguments = []
    }

    package init(format: StringFormat, arguments: [FormattedStringArgument], locale: Locale = .current) {
        self.init(
            value: "",
            format: format,
            arguments: arguments
        )
        self.value = localizedValue(locale: locale)
    }

    package init(_ string: String) {
        self.init(StringFormat(string))
    }

    package init(_ localizedString: LocalizedString) {
        self.init(StringFormat(localizedString))
    }
}

extension FormattedString: Equatable {
    package static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.format == rhs.format &&
            lhs.value == rhs.value
        // argument equality is inherently checked
        // through their inclusion in the value
    }
}

extension FormatStyle {
    func string(for input: Any, locale: Locale) -> String? {
        guard let input = input as? FormatInput else { return nil }
        let formatter = self.locale(locale)
        return formatter.format(input) as? String
    }
}
