import SwiftUI

struct UserLinguaRootViewModifier: ViewModifier {
    @ObservedObject private(set) var userLingua = UserLingua.shared
    
    func body(content: Content) -> some View {
        content
            .id(UUID()) //force the content to rerender when userLingua.objectWillChange fires
            .background {
                WindowReader(handler: userLingua.setWindow)
            }
            .onShake(perform: userLingua.didShake)
    }
}

extension View {
    public func userLinguaRootView() -> some View {
        modifier(UserLinguaRootViewModifier())
    }
}
