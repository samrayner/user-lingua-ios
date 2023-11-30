import SwiftUI

struct UserLinguaRootViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .environmentObject(UserLingua.shared)
            .background {
                WindowReader(handler: UserLingua.shared.setWindow)
            }
            .onShake(perform: UserLingua.shared.didShake)
    }
}

extension View {
    public func userLinguaRootView() -> some View {
        modifier(UserLinguaRootViewModifier())
    }
}
