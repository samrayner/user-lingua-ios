import SwiftUI

struct ShakeRecognizer: UIViewControllerRepresentable {
    let handler: () -> Void
    
    @MainActor
    final class ViewController: UIViewController {
        var didShakeHandler: () -> Void
        
        init(didShakeHandler: (@escaping () -> Void)) {
            self.didShakeHandler = didShakeHandler
            super.init(nibName: nil, bundle: nil)
            view.backgroundColor = .clear
            view.isUserInteractionEnabled = false
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func becomeFirstResponder() -> Bool {
            return true
        }

        override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
            guard motion == .motionShake else { return }
            didShakeHandler()
        }
    }
    
    func makeUIViewController(context: Context) -> ViewController {
        .init(didShakeHandler: handler)
    }
    
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
        uiViewController.didShakeHandler = handler
    }
}
