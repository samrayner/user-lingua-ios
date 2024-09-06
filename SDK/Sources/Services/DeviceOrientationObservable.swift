// DeviceOrientationObservable.swift

import Combine
import Foundation
import SwiftUI
import UIKit

public final class DeviceOrientationObservable: ObservableObject {
    @Published public var orientation: UIDeviceOrientation
    private var cancellable: AnyCancellable?

    public var didChangePublisher: AnyPublisher<UIDeviceOrientation, Never> {
        $orientation.dropFirst().eraseToAnyPublisher()
    }

    public init(orientation: UIDeviceOrientation = UIDevice.current.orientation) {
        self.orientation = orientation
    }

    public func start() {
        NotificationCenter.default
            .publisher(for: UIDevice.orientationDidChangeNotification)
            .map { _ in UIDevice.current.orientation }
            .filter { [weak self] in
                [.landscapeLeft, .landscapeRight, .portrait, .portraitUpsideDown].contains($0)
                    && $0 != self?.orientation
            }
            .assign(to: &$orientation)
    }

    public func started() -> Self {
        start()
        return self
    }

    public func stop() {
        cancellable = nil
    }
}
