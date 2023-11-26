import SwiftUI

extension View {
    internal static func UL(_ string: any StringProtocol) -> String {
        let string = String(string)
        let userLingua = UserLingua.shared
        
        if userLingua.state == .recordingStrings {
            userLingua.db.record(string: string)
        }
        
        return userLingua.displayString(for: string)
    }
    
    public func UL(_ string: any StringProtocol) -> String {
        Self.UL(string)
    }
}
