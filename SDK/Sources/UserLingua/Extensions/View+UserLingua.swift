import SwiftUI

extension View {
    internal static func UL(
        _ string: any StringProtocol,
        localize: Bool = UserLingua.shared.config.localizeStringWhenWrappedWithUL,
        dsoHandle: UnsafeRawPointer = #dsohandle
    ) -> String {
        let string = String(string)
        let userLingua = UserLingua.shared
        
        if localize {
            let bundle = Bundle(dsoHandle: dsoHandle) ?? .main
            let localizedString = LocalizedString(
                value: bundle.localizedString(forKey: string, value: nil, table: nil),
                localization: .init(key: string)
            )
            
            if userLingua.state == .recordingStrings {
                userLingua.db.record(localizedString: localizedString)
            }
            
            return userLingua.displayString(for: localizedString)
        } else {
            if userLingua.state == .recordingStrings {
                userLingua.db.record(string: string)
            }
            
            return userLingua.displayString(for: string)
        }
    }
    
    public func UL(_ string: any StringProtocol) -> String {
        Self.UL(string)
    }
}
