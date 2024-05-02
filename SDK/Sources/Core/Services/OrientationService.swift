// OrientationService.swift

import AsyncAlgorithms
import Dependencies
import Foundation
import Spyable
import UIKit

@Spyable
package protocol OrientationServiceProtocol {
    func orientationDidChange() async -> AsyncStream<UIDeviceOrientation>
}

package final class OrientationService: OrientationServiceProtocol {
    private var lastOrientation = UIDevice.current.orientation

    package func orientationDidChange() async -> AsyncStream<UIDeviceOrientation> {
        await AsyncStream(
            NotificationCenter.default
                .notifications(named: UIDevice.orientationDidChangeNotification)
                .map { _ in await UIDevice.current.orientation }
                .filter { [weak self] in
                    [.landscapeLeft, .landscapeRight, .portrait, .portraitUpsideDown].contains($0)
                        && $0 != self?.lastOrientation
                }
        )
    }
}

package enum OrientationServiceDependency: DependencyKey {
    package static let liveValue: any OrientationServiceProtocol = OrientationService()
    package static let previewValue: any OrientationServiceProtocol = OrientationServiceProtocolSpy()
    package static let testValue: any OrientationServiceProtocol = OrientationServiceProtocolSpy()
}
