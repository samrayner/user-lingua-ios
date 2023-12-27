// DetectionRedactionView.swift

import SwiftUI

extension RedactionReasons {
    fileprivate static let userLingua = RedactionReasons(rawValue: 1 << 6745) // arbitrary to avoid collisions
}

private struct DetectionRedactionView<Content: View>: View {
    @Environment(\.redactionReasons) var redactionReasons
    let content: Content
    let redact: Bool

    var body: some View {
        switch UserLingua.shared.state {
        case .detectingStrings:
            if redact {
                content.redacted(reason: [.placeholder, .userLingua])
            } else if redactionReasons.contains(.userLingua) {
                content.unredacted()
            } else {
                content
            }
        default:
            content
        }
    }
}

extension View {
    public func userLinguaDisabled(_ disabled: Bool = true) -> some View {
        DetectionRedactionView(content: self, redact: disabled)
    }
}
