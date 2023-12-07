import SwiftUI

private struct UserLinguaRootViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .environmentObject(UserLingua.shared)
    }
}

extension View {
    public func userLinguaRootView() -> some View {
        modifier(UserLinguaRootViewModifier())
    }
}
