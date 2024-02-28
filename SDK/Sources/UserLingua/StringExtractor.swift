// StringExtractor.swift

import Foundation
import Spyable
import SwiftUI
import SystemAPIAliases

@Spyable
protocol StringExtractorProtocol {
    func formattedString(
        localizedStringKey: LocalizedStringKey,
        locale: Locale,
        tableName: String?,
        bundle: Bundle?,
        comment: String?
    ) -> FormattedString
}

struct StringExtractor: StringExtractorProtocol {
    func formattedString(
        localizedStringKey: LocalizedStringKey,
        locale: Locale,
        tableName: String?,
        bundle: Bundle?,
        comment: String?
    ) -> FormattedString {
        // swiftlint:disable:next force_cast
        let key = Reflection.value("key", on: localizedStringKey) as! String

        let format = (bundle ?? .main).unswizzledLocalizedString(
            forKey: key,
            value: key,
            table: tableName
        )

        return FormattedString(
            format: .init(
                value: format,
                localization: .init(
                    key: key,
                    bundle: bundle,
                    tableName: tableName,
                    comment: comment
                )
            ),
            locale: locale,
            arguments: formattingArguments(localizedStringKey, locale: locale)
        )
    }

    private func formattedString(text: Text, locale: Locale) -> FormattedString? {
        if let verbatim = verbatim(text: text) {
            return .init(verbatim)
        }

        guard let storage = Reflection.value("storage", on: text),
              let textStorage = Reflection.value("anyTextStorage", on: storage)
        else { return nil }

        return switch "\(type(of: textStorage))" {
        case "LocalizedTextStorage":
            formattedString(localizedTextStorage: textStorage, locale: locale)
        case "LocalizedStringResourceStorage":
            localizedString(localizedStringResourceStorage: textStorage).map(FormattedString.init)
        case "AttributedStringTextStorage":
            // we probably want to support this in future
            nil
        default:
            // there are more types we will probably never support
            nil
        }
    }

    private func verbatim(text: Text) -> String? {
        guard let storage = Reflection.value("storage", on: text)
        else { return nil }

        return Reflection.value("verbatim", on: storage) as? String
    }

    private func localizedString(localizedStringResourceStorage storage: Any) -> LocalizedString? {
        guard let resource = Reflection.value("resource", on: storage) as? LocalizedStringResource
        else { return nil }

        let bundleURL = Reflection.value("_bundleURL", on: resource) as? URL
        let localeIdentifier = resource.locale.identifier

        let bundle = (bundleURL.flatMap(Bundle.init(url:)) ?? .main).path(
            forResource: localeIdentifier.replacingOccurrences(of: "_", with: "-"),
            ofType: "lproj"
        )
        .flatMap(Bundle.init(path:))

        return LocalizedString(
            value: String(localized: resource),
            localization: .init(
                key: resource.key,
                bundle: bundle,
                tableName: resource.table,
                comment: nil
            )
        )
    }

    private func formattedString(localizedTextStorage storage: Any, locale: Locale) -> FormattedString? {
        guard let localizedStringKey = Reflection.value("key", on: storage) as? LocalizedStringKey
        else { return nil }

        let bundle = Reflection.value("bundle", on: storage) as? Bundle
        let tableName = Reflection.value("table", on: storage) as? String
        let comment = Reflection.value("comment", on: storage) as? String

        return formattedString(
            localizedStringKey: localizedStringKey,
            locale: locale,
            tableName: tableName,
            bundle: bundle,
            comment: comment
        )
    }

    private func formattingArguments(_ localizedStringKey: LocalizedStringKey, locale: Locale) -> [FormattedStringArgument] {
        guard let arguments = Reflection.value("arguments", on: localizedStringKey) as? [Any]
        else { return [] }

        return arguments.compactMap { formattingArgument($0, locale: locale) }
    }

    private func formattingArgument(_ container: Any, locale: Locale) -> FormattedStringArgument? {
        guard let storage = Reflection.value("storage", on: container)
        else { return nil }

        if let textContainer = Reflection.value("text", on: storage),
           let text = Reflection.value(".0", on: textContainer) as? Text {
            return formattedString(text: text, locale: locale).map { .formattedString($0) }
        }

        if let formatStyleContainer = Reflection.value("formatStyleValue", on: storage),
           let formatStyle = Reflection.value("format", on: formatStyleContainer) as? any FormatStyle,
           let input = Reflection.value("input", on: formatStyleContainer) {
            return formatStyle.string(for: input, locale: locale).map { .cVarArg($0) }
        }

        if let valueContainer = Reflection.value("value", on: storage),
           let value = Reflection.value(".0", on: valueContainer) as? FormattedStringArgument {
            let formatter = Reflection.value(".1", on: valueContainer) as? Formatter
            let formattedArgument: FormattedStringArgument? = formatter
                .flatMap { $0.string(for: value) }
                .map { .cVarArg($0) }

            return formattedArgument ?? value
        }

        return nil
    }
}

extension FormatStyle {
    fileprivate func string(for input: Any, locale: Locale) -> String? {
        guard let input = input as? FormatInput else { return nil }
        let formatter = self.locale(locale)
        return formatter.format(input) as? String
    }
}
