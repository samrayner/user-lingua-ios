// TriggerObserver.swift

import Foundation
import Spyable

@Spyable
protocol TriggerObserverProtocol {
    func startObservingShake()
    func stopObservingShake()
}

final class TriggerObserver: TriggerObserverProtocol {
    private let onShake: () -> Void
    private var shakeObservation: NSObjectProtocol?

    init(onShake: @escaping () -> Void) {
        self.onShake = onShake
    }

    func startObservingShake() {
        shakeObservation = NotificationCenter.default.addObserver(forName: .deviceDidShake, object: nil, queue: nil) { [weak self] _ in
            self?.onShake()
        }
    }

    func stopObservingShake() {
        shakeObservation = nil
    }
}
