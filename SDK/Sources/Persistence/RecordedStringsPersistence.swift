// RecordedStringsPersistence.swift

import GRDB
import Models

public protocol RecordedStringsPersistence {
    func saveRecordedString(_ recordedString: RecordedString)
    func fetchRecordedStrings() -> [RecordedString]
    func fetchRecordedString(localized: LocalizedString) -> RecordedString?
    func fetchRecordedString(string: String) -> RecordedString?
}

extension Database: RecordedStringsPersistence {
    func saveRecordedString(_: Models.RecordedString) {
        fatalError()
    }

    func fetchRecordedStrings() -> [Models.RecordedString] {
        fatalError()
    }

    func fetchRecordedString(localized _: Models.LocalizedString) -> Models.RecordedString? {
        fatalError()
    }

    func fetchRecordedString(string _: String) -> Models.RecordedString? {
        fatalError()
    }
}

extension RecordedString: Codable, FetchableRecord, MutablePersistableRecord {}
