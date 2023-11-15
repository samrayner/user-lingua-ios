import SwiftUI

struct Localization: Hashable {
    var key: String
    var tableName: String?
    var comment: String?
}

struct LocalizedString: Hashable {
    var value: String
    var localization: Localization
}

struct Suggestion {
    var oldValue: String
    var newValue: String
    var locale: Locale
    var localization: Localization?
    var createdAt: Date = .now
    var modifiedAt: Date = .now
    var isSubmitted = false
    var screenshot: Image?
}

public class UserLingua {
    enum State {
        case disabled
        case recordingStrings
        case detectingStrings
        case previewingSuggestions
    }
    
    public struct Configuration {
        let highlightColor: Color
    }
    
    static let shared = UserLingua(config: .init(highlightColor: .green))
    
    let db = Database()
    let config: Configuration
    var state: State = .recordingStrings
    
    public init(config: Configuration) {
        self.config = config
    }
}

class Database {
    var stringRecord: [String] = [] {
        didSet {
            trimStringRecord()
        }
    }
    
    var localizations: [String: Set<LocalizedString>] = [:]
    var suggestions: [String: [Suggestion]] = [
        "Text value %@": [
            .init(
                oldValue: "Text value %@",
                newValue: "Sam2",
                locale: .current
            )
        ]
    ]
    
    private func trimStringRecord() {
        let softLimit = 1000
        let buffer = 500
        if stringRecord.count > softLimit + buffer {
            stringRecord.removeFirst(buffer)
        }
    }
    
    func record(string: String) {
        stringRecord.append(string)
    }
    
    func record(localizedString: LocalizedString) {
        record(string: localizedString.value)
        localizations[localizedString.value, default: []].insert(localizedString)
    }
    
    func suggestions(for oldValue: String) -> [Suggestion] {
        suggestions[oldValue, default: []].filter {
            $0.locale == .current
        }
    }
    
    func suggestion(for localizedString: LocalizedString) -> Suggestion? {
        let matchingValues = suggestions(for: localizedString.value)
        return matchingValues.first {
            $0.localization == localizedString.localization
        } ?? matchingValues.first
    }
    
    func suggestion(for oldValue: String) -> Suggestion? {
        suggestions(for: oldValue).first
    }
}

enum Reflection {
    static func value(
        _ label: String,
        on object: Any
    ) -> Any? {
        let reflection = Mirror(reflecting: object)
        return reflection.children
            .first(where: { $0.label == label })?
            .value
    }
}

extension Text {
    public func userLingua() -> Self {
        guard UserLingua.shared.state != .disabled
        else { return self }
        
        guard let storage = Reflection.value("storage", on: self)
        else { return self }
        
        if let value = Reflection.value("verbatim", on: storage) as? String {
            switch UserLingua.shared.state {
            case .disabled:
                return self
            case .recordingStrings:
                UserLingua.shared.db.record(string: value)
                return self
            case .detectingStrings:
                return text(string: value.tokenized())
            case .previewingSuggestions:
                let suggestion = UserLingua.shared.db.suggestion(for: value)
                return suggestion.map { text(string: $0.newValue) } ?? self
            }
        }
        
        guard let textStorage = Reflection.value("anyTextStorage", on: storage)
        else { return self }
        
        let textStorageType = "\(type(of: textStorage))"
        
        switch textStorageType {
        case "LocalizedTextStorage":
            guard let localizedString = localizedString(from: textStorage)
            else { return self }
            
            switch UserLingua.shared.state {
            case .disabled:
                return self
            case .recordingStrings:
                UserLingua.shared.db.record(localizedString: localizedString)
                return self
            case .detectingStrings:
                return text(string: localizedString.value.tokenized())
            case .previewingSuggestions:
                let suggestion = UserLingua.shared.db.suggestion(for: localizedString)
                return suggestion.map { text(string: $0.newValue) } ?? self
            }
        case "AttributedStringTextStorage":
            //we probably want to support this in future
            return self
        default:
            //there are more types we will probably never support
            return self
        }
    }
    
    private func text(string: String) -> Self {
        return Self(verbatim: string).foregroundColor(UserLingua.shared.config.highlightColor)
    }
    
    private func localizedString(from localizedTextStorage: Any) -> LocalizedString? {
        guard let localizedStringKey = Reflection.value("key", on: localizedTextStorage)
        else { return nil }
        
        guard let key = Reflection.value("key", on: localizedStringKey) as? String
        else { return nil }
        
        let bundle = Reflection.value("bundle", on: localizedTextStorage) as? Bundle
        let tableName = Reflection.value("table", on: localizedTextStorage) as? String
        let comment = Reflection.value("comment", on: localizedTextStorage) as? String
        
        let value = bundle?.localizedString(forKey: key, value: nil, table: tableName)
        
        return LocalizedString(
            value: value ?? key,
            localization: .init(
                key: key,
                tableName: tableName,
                comment: comment
            )
        )
    }
}

extension StringProtocol {
    func tokenized() -> String {
        let utf16 = self.utf16
        var array = Array(utf16)
        
        var i = 0
        while i < utf16.count/2 {
            array.swapAt(i, utf16.count - i - 1)
            i += 2
        }
        
        return String(utf16CodeUnits: array, count: array.count)
    }
}
