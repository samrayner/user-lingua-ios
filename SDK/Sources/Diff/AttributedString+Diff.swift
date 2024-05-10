// AttributedString+Diff.swift

import Foundation
import KSSDiff

package struct DiffAttributes {
    let insert: [NSAttributedString.Key: Any]
    let delete: [NSAttributedString.Key: Any]
    let same: [NSAttributedString.Key: Any]

    package init(
        insert: [NSAttributedString.Key: Any] = [:],
        delete: [NSAttributedString.Key: Any] = [:],
        same: [NSAttributedString.Key: Any] = [:]
    ) {
        self.insert = insert
        self.delete = delete
        self.same = same
    }
}

extension AttributedString {
    package init(old: String, new: String, diffAttributes: DiffAttributes) {
        let diffs = DiffMatchPatch(diffTimeout: 0)
            .main(Substring(old), Substring(new))

        self = diffs
            .compactMap { diff in
                if diff.isInsert, let text = diff.inNew {
                    AttributedString(text, attributes: .init(diffAttributes.insert))
                } else if diff.isDelete, let text = diff.inOriginal {
                    AttributedString(text, attributes: .init(diffAttributes.delete))
                } else if diff.isEqual, let text = diff.inNew {
                    AttributedString(text, attributes: .init(diffAttributes.same))
                } else {
                    nil
                }
            }
            .reduce(into: AttributedString()) { string, substring in
                string.append(substring)
            }
    }
}
