// AttributedString+Diff.swift

import DiffMatchPatch
import Foundation

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
        let diffMatchPatch = DiffMatchPatch()
        diffMatchPatch.diff_Timeout = TimeInterval(1.0)

        let nsArray = diffMatchPatch.diff_main(ofOldString: old, andNewString: new)
        diffMatchPatch.diff_cleanupSemantic(nsArray)

        guard let diffs = nsArray as? [Diff] else {
            self = AttributedString(new)
            return
        }

        self = diffs
            .compactMap { diff in
                switch diff.operation {
                case DIFF_INSERT:
                    AttributedString(diff.text, attributes: .init(diffAttributes.insert))
                case DIFF_DELETE:
                    AttributedString(diff.text, attributes: .init(diffAttributes.delete))
                case DIFF_EQUAL:
                    AttributedString(diff.text, attributes: .init(diffAttributes.same))
                default:
                    nil
                }
            }
            .reduce(into: AttributedString()) { string, substring in
                string.append(substring)
            }
    }
}
