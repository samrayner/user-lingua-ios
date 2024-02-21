// StringsRepository.swift

import Spyable

@Spyable
protocol StringsRepositoryProtocol {
    func record(string: String)
    func record(localizedString: LocalizedString)
    func recordedStrings() -> [RecordedString]
    func recordedString(localizedOriginal: LocalizedString) -> RecordedString?
    func recordedString(original: String) -> RecordedString?
}

final class StringsRepository: StringsRepositoryProtocol {
    private var stringRecord: [String: [RecordedString]] = [:]

    init() {}

    func record(string: String) {
        stringRecord[string, default: []].append(RecordedString(string, localization: nil))
    }

    func record(localizedString: LocalizedString) {
        guard localizedString.localization.bundle?.bundleURL.lastPathComponent != "UIKitCore.framework"
        else { return }

        let recordedString = RecordedString(
            localizedString.value,
            localization: localizedString.localization
        )

        stringRecord[localizedString.value, default: []].append(recordedString)
    }

    func recordedStrings() -> [RecordedString] {
        stringRecord
            .flatMap { $0.value }
            .sorted { $0.recordedAt > $1.recordedAt }
    }

    private func recordedStrings(original: String) -> [RecordedString] {
        stringRecord[original] ?? []
    }

    func recordedString(localizedOriginal: LocalizedString) -> RecordedString? {
        let matchingValues = recordedStrings(original: localizedOriginal.value)
        return matchingValues.last {
            $0.localization == localizedOriginal.localization
        } ?? matchingValues.last
    }

    func recordedString(original: String) -> RecordedString? {
        let recorded = recordedStrings(original: original)
        return recorded.last { $0.localization != nil } ?? recorded.last
    }
}
