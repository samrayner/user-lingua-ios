// KeyboardNotification.swift

import Foundation
import SwiftUI

struct KeyboardNotification: Equatable {
    let beginFrame: CGRect
    let endFrame: CGRect
    let animation: Animation?

    init?(userInfo: [AnyHashable: Any]?) {
        guard let beginFrame = userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? CGRect,
              let endFrame = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else { return nil }

        self.beginFrame = beginFrame
        self.endFrame = endFrame

        guard let duration = userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curveValue = userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int,
              let uiKitCurve = UIView.AnimationCurve(rawValue: curveValue)
        else {
            self.animation = nil
            return
        }

        let timing = UICubicTimingParameters(animationCurve: uiKitCurve)

        self.animation = .timingCurve(
            Double(timing.controlPoint1.x),
            Double(timing.controlPoint1.y),
            Double(timing.controlPoint2.x),
            Double(timing.controlPoint2.y),
            duration: duration
        )
    }
}
