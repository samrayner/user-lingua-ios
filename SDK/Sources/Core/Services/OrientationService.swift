// OrientationService.swift

import Combine
import Dependencies
import Foundation
import UIKit

// sourcery: AutoMockable
public protocol OrientationServiceProtocol {
    func orientationDidChange() async -> AsyncStream<UIDeviceOrientation>
}

public final class OrientationService: OrientationServiceProtocol {
    private var lastOrientation = UIDevice.current.orientation

    @MainActor
    public func orientationDidChange() async -> AsyncStream<UIDeviceOrientation> {
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

public enum OrientationServiceDependency: DependencyKey {
    public static let liveValue: any OrientationServiceProtocol = OrientationService()
    public static let previewValue: any OrientationServiceProtocol = OrientationServiceProtocolMock()
    public static let testValue: any OrientationServiceProtocol = OrientationServiceProtocolMock()
}
