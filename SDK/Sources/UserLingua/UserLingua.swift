import UIKit
import SwiftUI
import OrderedCollections
import Vision

struct Localization: Hashable {
    var key: String
    var tableName: String?
    var comment: String?
}

struct LocalizedString: Hashable {
    var value: String
    var localization: Localization
}

struct TokenizedString: Hashable {
    let value: String
    let token: String
    
    init(_ value: String) {
        self.value = value
        self.token = value.tokenized()
    }
}

struct Suggestion {
    var oldValue: String
    var newValue: String
    var locale: Locale
    var localization: Localization?
    var createdAt: Date = .now
    var modifiedAt: Date = .now
    var isSubmitted = false
    var screenshot: UIImage?
}

final public class UserLingua {
    enum State {
        case disabled
        case recordingStrings
        case detectingStrings
        case highlightingStrings
        case previewingSuggestion
    }
    
    public struct Configuration {
        let highlightColor: Color
        
        public init(
            highlightColor: Color = .accentColor
        ) {
            self.highlightColor = highlightColor
        }
    }
    
    public static let shared = UserLingua()
    
    let db = Database()
    var config = Configuration()
    let detector = Detector()
    var state: State = .disabled
    
    public init() {}
    
    public func enable(config: Configuration = .init()) {
        self.config = config
        state = .detectingStrings
        detector.findAllText()
    }
}

final class Database {
    var stringRecord: OrderedSet<TokenizedString> = [] {
        didSet { stringRecord.trimFront() }
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
    
    func record(string: String) {
        let tokenized = TokenizedString(string)
        stringRecord.remove(tokenized)
        stringRecord.append(tokenized)
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

private enum Reflection {
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
            case .disabled, .highlightingStrings:
                return self
            case .recordingStrings:
                UserLingua.shared.db.record(string: value)
                return self
            case .detectingStrings:
                let tokenizedString = TokenizedString(value)
                return text(string: tokenizedString.token)
            case .previewingSuggestion:
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
            case .disabled, .highlightingStrings:
                return self
            case .recordingStrings:
                UserLingua.shared.db.record(localizedString: localizedString)
                return self
            case .detectingStrings:
                let tokenizedString = TokenizedString(localizedString.value)
                return text(string: tokenizedString.token)
            case .previewingSuggestion:
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

extension OrderedSet {
    mutating func trimFront(softLimit: Int = 1000, buffer: Int = 500) {
        if count > softLimit + buffer {
            removeFirst(buffer)
        }
    }
}

final class Detector {
    func snapshot() -> UIImage {
        UIImage(resource: .screenshot)
    }
    
    public func findAllText() {
        guard let cgImage = snapshot().cgImage else { return }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
        request.recognitionLevel = .fast
        request.automaticallyDetectsLanguage = false
        request.usesLanguageCorrection = false
        
        do {
            try requestHandler.perform([request])
        } catch {
            print("Unable to perform the requests: \(error).")
        }
    }
    
    private func recognizeTextHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNRecognizedTextObservation]
        else { return }
        
        let recognizedText = observations
            .compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            .joined(separator: " ")
        
        print(recognizedText)
    }
}
