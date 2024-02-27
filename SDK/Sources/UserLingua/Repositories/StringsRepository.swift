// StringsRepository.swift

import Spyable

@Spyable
protocol StringsRepositoryProtocol {
    func record(formatted: FormattedString)
    func record(localized: LocalizedString)
    func record(string: String)
    func recordedStrings() -> [RecordedString]
    func recordedString(formatted: FormattedString) -> RecordedString?
    func recordedString(localized: LocalizedString) -> RecordedString?
    func recordedString(string: String) -> RecordedString?
}

final class StringsRepository: StringsRepositoryProtocol {
    private var stringRecord: [String: [RecordedString]] = [:]

    init() {}

    func record(formatted formattedString: FormattedString) {
        for argument in formattedString.arguments {
            switch argument {
            case let .formattedString(formattedString):
                record(formatted: formattedString)
            case .cVarArg:
                break // don't record
            }
        }

        // TODO:
        // if we find an existing record of the same string
        // which is localized and has argument placeholders
        // but no arguments then populate the arguments -
        // this updates localized records with formatting because
        // formatting always comes after localization of the format
        // let old = stringRecord[formattedString.value]?.first {

        // }

        stringRecord[formattedString.value, default: []]
            .append(RecordedString(formattedString))
    }

    func record(format: StringFormat) {
        if let localizedString = format.localizedValue {
            record(localized: localizedString)
        } else {
            record(string: format.value)
        }
    }

    func record(string: String) {
        stringRecord[string, default: []].append(
            RecordedString(FormattedString(StringFormat(string)))
        )
    }

    func record(localized localizedString: LocalizedString) {
        guard localizedString.localization.bundle?.bundleURL.lastPathComponent != "UIKitCore.framework"
        else { return }

        stringRecord[localizedString.value, default: []].append(
            RecordedString(FormattedString(StringFormat(localizedString)))
        )
    }

    func recordedStrings() -> [RecordedString] {
        stringRecord
            .flatMap { $0.value }
            .sorted { $0.recordedAt > $1.recordedAt }
    }

    private func recordedStrings(string: String) -> [RecordedString] {
        stringRecord[string] ?? []
    }

    func recordedString(formatted formattedString: FormattedString) -> RecordedString? {
        recordedString(format: formattedString.format)
    }

    func recordedString(format: StringFormat) -> RecordedString? {
        if let localizedString = format.localizedValue {
            recordedString(localized: localizedString)
        } else {
            recordedString(string: format.value)
        }
    }

    func recordedString(localized localizedString: LocalizedString) -> RecordedString? {
        let matchingValues = recordedStrings(string: localizedString.value)
        return matchingValues.last {
            $0.localization == localizedString.localization
        } ?? matchingValues.last
    }

    func recordedString(string: String) -> RecordedString? {
        let recorded = recordedStrings(string: string)
        return recorded.last { $0.localization != nil } ?? recorded.last
    }
}

extension String {
    private var argumentPlaceholderCount: Int {
        matches(of: #/[^%]%/#).count
    }
}
