// OrientationService.swift

import Combine
import Foundation
import UIKit

// sourcery: AutoMockable
package protocol OrientationServiceProtocol {
    func orientationDidChange() async -> AsyncStream<UIDeviceOrientation>
}

package final class OrientationService: OrientationServiceProtocol {
    private var lastOrientation = UIDevice.current.orientation

    @MainActor
    package func orientationDidChange() async -> AsyncStream<UIDeviceOrientation> {
        AsyncStream(
            NotificationCenter.default
                .publisher(for: UIDevice.orientationDidChangeNotification)
                .map { _ in UIDevice.current.orientation }
                .filter { [weak self] in
                    [.landscapeLeft, .landscapeRight, .portrait, .portraitUpsideDown].contains($0)
                        && $0 != self?.lastOrientation
                }
                .handleEvents(
                    receiveOutput: { [weak self] in
                        self?.lastOrientation = $0
                    }
                )
                .values
        )
    }
}
