import SwiftUI
import ViewInspector

extension View {
    private func test() throws {
        for textView in try self.inspect().findAll(ViewType.Text.self) {
            print(try textView.string())
        }
    }
    
    public func userLingua() -> some View {
        self.onAppear {
            try! test()
        }
    }
}
