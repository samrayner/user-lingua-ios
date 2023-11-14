import SwiftUI

struct LocalizedString: Equatable {
    var key: String
    var value: String
    var bundle: Bundle = .main
    var tableName: String?
    var comment: String?
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.key == rhs.key &&
        lhs.value == rhs.value &&
        lhs.bundle == rhs.bundle &&
        lhs.tableName == rhs.tableName
    }
}

struct LocalizedStringLog {
    var localizedString: LocalizedString
    var firstInstanceAt: Date = .now
    var lastInstanceAt: Date = .now
    var instanceCount: UInt = 1
}

struct Suggestion {
    var oldValue: String
    var newValue: String
    var languageCode: String
    var key: String?
    var createdAt: Date = .now
    var modifiedAt: Date = .now
    var isSubmitted = false
    var screenshot: Image?
}

class UserLingua {
    struct Configuration {
        let highlightColor: Color
    }
    
    static let shared = UserLingua(config: .init(highlightColor: .red))
    
    let db = Database()
    let config: Configuration
    
    public init(config: Configuration) {
        self.config = config
    }
}

class Database {
    var localizedStringLogs: [LocalizedStringLog] = []
    var suggestions: [Suggestion] = [
        .init(oldValue: "Text value", newValue: "Sam", languageCode: "en", key: "text_key")
    ]
    
    func logLocalizedStringInstance(_ localizedString: LocalizedString) {
        if var existing = localizedStringLogs.first(
            where: { $0.localizedString == localizedString }
        ) {
            existing.instanceCount += 1
            existing.lastInstanceAt = .now
        } else {
            localizedStringLogs.append(
                .init(localizedString: localizedString)
            )
        }
    }
    
    func suggestions(for oldValue: String) -> [Suggestion] {
        suggestions.filter { $0.oldValue == oldValue }
    }
    
    func suggestion(for localizedString: LocalizedString) -> Suggestion? {
        let matchingValues = suggestions(for: localizedString.value)
        return matchingValues.first {
            $0.key == localizedString.key
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
        guard let storage = Reflection.value("storage", on: self)
        else { return self }
        
        if let value = Reflection.value("verbatim", on: storage) as? String {
            let suggestion = UserLingua.shared.db.suggestion(for: value)
            return suggestion.map { Text($0.newValue) } ?? self
        }
        
        guard let textStorage = Reflection.value("anyTextStorage", on: storage)
        else { return self }
        
        let textStorageType = "\(type(of: textStorage))"
        
        switch textStorageType {
        case "LocalizedTextStorage":
            guard let value = localizedString(from: textStorage)
            else { return self }
            
            UserLingua.shared.db.logLocalizedStringInstance(value)
            
            let suggestion = UserLingua.shared.db.suggestion(for: value)
            return suggestion.map { Text($0.newValue) } ?? self
        case "AttributedStringTextStorage":
            //we probably want to support this in future
            return self
        default:
            return self
        }
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
            key: key,
            value: value ?? key,
            bundle: .main,
            tableName: tableName,
            comment: comment
        )
    }
}
