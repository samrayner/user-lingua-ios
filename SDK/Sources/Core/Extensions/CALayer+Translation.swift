// CALayer+Translation.swift

import UIKit

extension CALayer {
    package var translationIn2D: CGPoint {
        // translation matrix is [1 0 0 0; 0 1 0 0; 0 0 1 0; tx ty tz 1]
        .init(
            x: transform.m41,
            y: transform.m42
        )
    }

    // swiftlint:disable:next identifier_name
    package func translate(x: CGFloat = 0, y: CGFloat = 0, z: CGFloat = 0) {
        transform = CATransform3DTranslate(CATransform3DIdentity, x, y, z)
    }

    package func removeTranslation() {
        translate(x: 0, y: 0, z: 0)
    }
}
