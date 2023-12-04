import SwiftUI

extension View {
    public func UL(
        _ string: any StringProtocol,
        localize: Bool = UserLingua.shared.config.localizeStringWhenWrappedWithUL
    ) -> String {
        UserLingua.shared.processString(String(string), localize: localize)
    }
}
