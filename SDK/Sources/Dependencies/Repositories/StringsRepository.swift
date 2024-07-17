// StringsRepository.swift

import Foundation
import Models

// sourcery: AutoMockable
public protocol StringsRepositoryProtocol {
    func record(formatted: FormattedString)
    func record(localized: LocalizedString)
    func record(string: String)
    func recordedStrings() -> [RecordedString]
    func recordedString(formatted: FormattedString) -> RecordedString?
    func recordedString(localized: LocalizedString) -> RecordedString?
    func recordedString(string: String) -> RecordedString?
}

public final class StringsRepository: StringsRepositoryProtocol {
    private var stringRecord: [String: [RecordedString]]

    public init(stringRecord: [String: [RecordedString]] = [:]) {
        self.stringRecord = stringRecord
    }

    public func record(formatted formattedString: FormattedString) {
        guard !formattedString.shouldIgnore else { return }

        var formattedString = formattedString

        for index in 0 ..< formattedString.arguments.count {
            switch formattedString.arguments[index] {
            case .formattedString:
                // all formatted string arguments should
                // already have been recorded at this point
                // except maybe Text arguments inside a
                // LocalizedStringKey?
                break // record(formatted: formattedString)
            case let .cVarArg(cVarArg):
                // if we've recorded a localization or format of the
                // argument then we want to embed that information in
                // the parent string record. It would be good to have
                // a more reliable match than just a string lookup though
                // as this could apply an unrelated localization for a common
                // phrase
                if let recorded = (cVarArg as? String).flatMap(recordedString(string:)) {
                    formattedString.arguments[index] = .formattedString(recorded.formatted)
                }
            case .formattableInput:
                // used for things like dates so not a localized string we
                // need to worry about recording
                break
            }
        }

        // if we find an existing record of the same string format
        // which has a number of unpopulated placeholders
        // equal to the number of arguments we are recording
        // then we can be reasonably confident we are recording
        // the formatting of that previously recorded string
        // so we can augment this record with the same localization
        // and delete the unformatted record
        if let unformattedRecordIndex = stringRecord[formattedString.format.value]?.lastIndex(where: {
            $0.value.argumentPlaceholderCount == formattedString.arguments.count
        }) {
            let unformattedRecord = stringRecord[formattedString.format.value]?[unformattedRecordIndex]
            formattedString.format.localization = unformattedRecord?.localization
            stringRecord[formattedString.format.value]?.remove(at: unformattedRecordIndex)
            // print("Discarded localized record: \(formattedString.format.value)")
        }

        stringRecord[formattedString.value, default: []].append(
            RecordedString(formattedString)
        )

        // print("Recorded formatted: \(formattedString.value)")
    }

    public func record(localized localizedString: LocalizedString) {
        guard !localizedString.shouldIgnore else { return }

        stringRecord[localizedString.value, default: []].append(
            RecordedString(localizedString)
        )

        // print("Recorded localized: \(localizedString.value)")
    }

    public func record(string: String) {
        stringRecord[string, default: []].append(
            RecordedString(string)
        )

        // print("Recorded string: \(string)")
    }

    public func recordedStrings() -> [RecordedString] {
        stringRecord
            .flatMap { $0.value }
            .sorted { $0.recordedAt > $1.recordedAt }
    }

    private func recordedStrings(string: String) -> [RecordedString] {
        stringRecord[string] ?? []
    }

    public func recordedString(formatted formattedString: FormattedString) -> RecordedString? {
        if let localizedString = formattedString.format.localized {
            recordedString(localized: localizedString)
        } else {
            recordedString(string: formattedString.value)
        }
    }

    public func recordedString(localized localizedString: LocalizedString) -> RecordedString? {
        let matchingValues = recordedStrings(string: localizedString.value)
        return matchingValues.last {
            $0.localization == localizedString.localization
        } ?? matchingValues.last
    }

    public func recordedString(string: String) -> RecordedString? {
        let recorded = recordedStrings(string: string)
        return recorded.last { $0.localization != nil } ?? recorded.last
    }
}

extension String {
    fileprivate var argumentPlaceholderCount: Int {
        StringFormat.placeholderRegex
            .matches(in: self, range: NSRange(startIndex..., in: self))
            .count
    }
}
