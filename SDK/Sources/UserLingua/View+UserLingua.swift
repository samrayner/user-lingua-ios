import SwiftUI

struct UserLinguaRootView<Content: View>: View {
    @ObservedObject private(set) var userLingua = UserLingua.shared
    
    let content: Content

    init(@ViewBuilder _ content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
        .background {
            WindowReader { window in
                UserLingua.shared.window = window
            }
        }
    }
}

struct UserLinguaRootViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        UserLinguaRootView {
            content
        }
    }
}

extension View {
    public func userLinguaRootView() -> some View {
        modifier(UserLinguaRootViewModifier())
    }
}
