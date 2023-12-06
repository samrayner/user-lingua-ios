import SwiftUI

struct UserLinguaRootViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .environmentObject(UserLingua.shared)
            .background {
                WindowReader(handler: UserLingua.shared.setWindow)
            }
    }
}

extension View {
    public func userLinguaRootView() -> some View {
        modifier(UserLinguaRootViewModifier())
    }
}
