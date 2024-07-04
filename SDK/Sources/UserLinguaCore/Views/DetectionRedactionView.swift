// DetectionRedactionView.swift

import CombineFeedback
import SwiftUI

extension RedactionReasons {
    fileprivate static let userLingua = RedactionReasons(rawValue: 1 << 170_819) // arbitrary to avoid collisions
}

private struct DetectionRedactionView<Content: View>: View {
    @Environment(\.redactionReasons) var redactionReasons
    let content: Content
    let redact: Bool

    var body: some View {
        if UserLinguaClient.shared.isTakingScreenshot {
            if redact {
                content.redacted(reason: [.placeholder, .userLingua])
            } else if redactionReasons.contains(.userLingua) {
                content.unredacted()
            } else {
                content
            }
        } else {
            content
        }
    }
}

extension View {
    public func userLinguaDisabled(_ disabled: Bool = true) -> some View {
        DetectionRedactionView(content: self, redact: disabled)
    }
}
