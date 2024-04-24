// Strings.generated.swift

// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum Strings {
    /// UserLingua
    public static let sdkName = Strings.tr("Localizable", "sdkName", fallback: "UserLingua")
    public enum Inspection {
        /// Submit suggestion
        public static let submitButton = Strings.tr("Localizable", "inspection.submit_button", fallback: "Submit suggestion")
        public enum LanguagePicker {
            /// Language
            public static let title = Strings.tr("Localizable", "inspection.language_picker.title", fallback: "Language")
        }

        public enum Localization {
            public enum Comment {
                /// Comment
                public static let title = Strings.tr("Localizable", "inspection.localization.comment.title", fallback: "Comment")
            }

            public enum Key {
                /// Key
                public static let title = Strings.tr("Localizable", "inspection.localization.key.title", fallback: "Key")
            }

            public enum Table {
                /// File
                public static let title = Strings.tr("Localizable", "inspection.localization.table.title", fallback: "File")
            }
        }

        public enum SuggestionField {
            ///
            public static let placeholder = Strings.tr("Localizable", "inspection.suggestion_field.placeholder", fallback: "")
        }
    }
}

// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension Strings {
    private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
        let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
        return String(format: format, locale: Locale.current, arguments: args)
    }
}

// swiftlint:disable convenience_type
private final class BundleToken {
    static let bundle: Bundle = {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: BundleToken.self)
        #endif
    }()
}

// swiftlint:enable convenience_type
