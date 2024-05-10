// StringExtension.swift

import Foundation

@available(OSX 10.15, *)
extension String {
    /**
     Compute the differences in this string from another string. In the returned array, the `inNew` items will be
     substrings of this string while the `inOriginal` items will be substrings of `s`.

     - note: This is a wrapper around the `DiffMatchPatch` class that assumes no timeout and that
     strips out any equality items. In this manner, the return value contains only the differences (the insertions and
     the deletions). If you wish more control over the difference parameters, or you wish to retain the equality
     "differences", then you will need to call `DiffMatchPatch.main` manually.
     */
    public func differencesFrom(_ s: String) -> [Difference] {
        let dmp = DiffMatchPatch(diffTimeout: 0)
        var diffs = dmp.main(Substring(s), Substring(self))
        if !diffs.isEmpty {
            diffs.removeAll { $0.isEqual }
        }
        return diffs
    }
}
