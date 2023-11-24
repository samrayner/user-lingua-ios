import SwiftUI

extension View {
    public func userLingua(_ string: any StringProtocol) -> String {
        let string = String(string)
        let userLingua = UserLingua.shared
        
        if userLingua.state == .recordingStrings {
            userLingua.db.record(string: string)
        }
        
        return userLingua.displayString(for: string)
    }
}
